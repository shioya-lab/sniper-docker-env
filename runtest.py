#%%

#!/usr/bin/python3

import subprocess
import docker
import os
import sqlite3
from multiprocessing import Pool

flatten = lambda x: [z for y in x for z in (flatten(y) if hasattr(y, '__iter__') and not isinstance(y, str) else (y,))]

def get_sqlite_info_with_file (file_str):
    print("Opening %s ..." % (file_str))
    try:
        sql3_conn = sqlite3.connect(file_str)
    except sqlite3.OperationalError:
        print ('sqlite3 file error ' + file_str)
        exit()

    prefix = sql3_conn.execute("SELECT * FROM 'prefixes'").fetchall()
    names  = sql3_conn.execute("SELECT * FROM 'names'").fetchall()
    values = sql3_conn.execute("SELECT * FROM 'values'").fetchall()
      
    sql_dict = dict()
    for elem in values:
        prefix_id  = elem[0]
        id         = elem[1]
        # ore_id = elem[2]
        value     = elem[3]
        
        assert(names[id-1][0] == id)
        module = names[id-1][1]
        info_name = names[id-1][2]
        if not sql_dict.get(module):
            sql_dict[module] = dict()
        if not sql_dict[module].get(info_name):
            sql_dict[module][info_name] = dict()
        sql_dict[module][info_name][prefix[prefix_id-1][1]] = value
     
    return sql_dict


cli = docker.from_env()

user_id     = os.getuid()
group_id    = os.getgid()
current_dir = os.path.abspath("./")

rivec_benchmarks = [
    'axpy', 
    'blackscholes', 
    'canneal', 
    'jacobi-2d', 
    'particlefilter', 
    'pathfinder', 
    'streamcluster',
    'swaptions'
]

benchmarks = rivec_benchmarks + [
    'spmv', 
    'fftw3',
#    'dhrystone'
]

# build_command = ["make", "-C", "vector_benches/rivec1.0/_axpy",
#                  "runsniper-ooo-v", "VLEN=256", "DLEN=128", "L2PREF=l2_stream", "L1PREF_POLICY=l1d_pref_load"]

config_set = [{'name': 'L1D Prefetch None'             , 'dir': 'none_l1d_pref',          'vlen':512, 'dlen':128, 'config': ["riscv-mediumboom.v512_d128", "l1d_none_pref"  , "l2_stream", "l1d_pref_load"]},
              {'name': 'L1D Prefetch Simple'           , 'dir': 'simple_l1d_pref',        'vlen':512, 'dlen':128, 'config': ["riscv-mediumboom.v512_d128", "l1d_simple_pref", "l2_stream", "l1d_pref_load"]},
              {'name': 'L1D Prefetch Stride'           , 'dir': 'stride_l1d_pref',        'vlen':512, 'dlen':128, 'config': ["riscv-mediumboom.v512_d128", "l1d_stride_pref", "l2_stream", "l1d_pref_load"]},
              {'name': 'L1D Prefetch Vector(Degree  1)', 'dir': 'vec_l1d_pref_degree_01', 'vlen':512, 'dlen':128, 'config': ["riscv-mediumboom.v512_d128", "l1d_vec_pref"   , "l2_stream", "l1d_pref_load", "vec_pref_degree_1" ]},
              {'name': 'L1D Prefetch Vector(Degree  2)', 'dir': 'vec_l1d_pref_degree_02', 'vlen':512, 'dlen':128, 'config': ["riscv-mediumboom.v512_d128", "l1d_vec_pref"   , "l2_stream", "l1d_pref_load", "vec_pref_degree_2" ]},
              {'name': 'L1D Prefetch Vector(Degree  4)', 'dir': 'vec_l1d_pref_degree_04', 'vlen':512, 'dlen':128, 'config': ["riscv-mediumboom.v512_d128", "l1d_vec_pref"   , "l2_stream", "l1d_pref_load", "vec_pref_degree_4" ]},
              {'name': 'L1D Prefetch Vector(Degree  8)', 'dir': 'vec_l1d_pref_degree_08', 'vlen':512, 'dlen':128, 'config': ["riscv-mediumboom.v512_d128", "l1d_vec_pref"   , "l2_stream", "l1d_pref_load", "vec_pref_degree_8" ]},
              {'name': 'L1D Prefetch Vector(Degree 16)', 'dir': 'vec_l1d_pref_degree_16', 'vlen':512, 'dlen':128, 'config': ["riscv-mediumboom.v512_d128", "l1d_vec_pref"   , "l2_stream", "l1d_pref_load", "vec_pref_degree_16"]},
              ]
    
#%%

def run_sniper(config, application):
    
    sift_file = 'rvv-test_v' + str(config['vlen']) + ".sift"
    
    build_command = flatten([os.path.join(current_dir, "sniper/run-sniper"), "--roi",
                     "-v", 
                     "-c", os.path.join(current_dir,"sniper/config/riscv-base.cfg"),
                     [["-c", os.path.join(current_dir, "sniper/config/" + c + ".cfg")] for c in config['config']],
                     "--traces=" + os.path.join(current_dir, "vector_benches/rivec1.0/_" + application + "/" + sift_file)])
    # print(build_command)
    print("start " + application + " with " + config['dir'] + " ...")
    
    work_dir = application + "_" + config['dir']
    
    client = docker.from_env()
    os.makedirs (work_dir, exist_ok=True)
    build_result = client.containers.run(image="msyksphinz/ubuntu:20.04-work-sniper-kimura-llvm16",
                                      auto_remove=True,
                                      user=user_id,
                                      volumes={current_dir: {'bind': current_dir, 'mode': 'rw'}},
                                      working_dir=os.path.join(current_dir, work_dir),
                                      detach=True,
                                      tty=True,
                                      command=build_command
                                      )
    
    with open(os.path.join(work_dir, 'sniper.log'), mode='w') as f:
        for line in build_result.logs(stream=True):
            # message = line.decode('utf-8').strip()
            message = line.decode('utf-8')
            # if message:
            #     print(message, end='')
            f.write(message)

    sim_sq3_filename = os.path.join(work_dir, "sim.stats.sqlite3")

    subprocess.run(["python3", "../vector_benches/scripts/dump_sqlite3.py", os.path.join("../", sim_sq3_filename)], 
                   cwd=work_dir)


#%%

def run_sniper_wrapper(args):
    run_sniper(*args)

with Pool(maxtasksperchild=128) as pool:
    try:
        args_list = [(c, a) for c in config_set for a in benchmarks]
        pool.map(run_sniper_wrapper, args_list)
    except KeyboardInterrupt:
        print("Caught KeyboardInterrupt, terminating workers", end="\r\n")
        pool.terminate()
        pool.join()


# %%

import plotly.graph_objects as go
import pandas as pd

pd.options.plotting.backend = "plotly"
pd.options.display.float_format = "{:.2f}".format

glbl_stats_cycle             = pd.DataFrame()
glbl_stats_num_prefetch      = pd.DataFrame()
glbl_stats_num_hits_prefetch = pd.DataFrame()
glbl_stats_num_eviction      = pd.DataFrame()

for app in benchmarks:
    cycles = dict()

    stats_cycle             = pd.Series(name=app)
    stats_num_prefetch      = pd.Series(name=app)
    stats_num_hits_prefetch = pd.Series(name=app)
    stats_num_eviction      = pd.Series(name=app)

    for config in config_set:
        work_dir = app + "_" + config['dir']
        sim_sq3_filename = os.path.join(work_dir, "sim.stats.sqlite3")

        sim_info_dict = get_sqlite_info_with_file(sim_sq3_filename)

        stats_cycle            [config['name']] = sim_info_dict['thread']['time_by_core[0]']['roi-end'] / 500000
        stats_num_prefetch     [config['name']] = sim_info_dict['L1-D'] ['prefetches']      ['roi-end'] if 'prefetches' in sim_info_dict['L1-D'] else 0
        stats_num_hits_prefetch[config['name']] = sim_info_dict['L1-D'] ['hits-prefetch']   ['roi-end'] if 'prefetches' in sim_info_dict['L1-D'] else 0
        stats_num_eviction     [config['name']] = sim_info_dict['L1-D'] ['evict-S']   ['roi-end'] if 'evict-S' in sim_info_dict['L1-D'] else 0 + \
                                                       sim_info_dict['L1-D'] ['evict-M']   ['roi-end'] if 'evict-M' in sim_info_dict['L1-D'] else 0

    glbl_stats_cycle = pd.concat([glbl_stats_cycle, stats_cycle], axis=1)
    glbl_stats_num_prefetch      = pd.concat([glbl_stats_num_prefetch     , stats_num_prefetch     ], axis=1)
    glbl_stats_num_hits_prefetch = pd.concat([glbl_stats_num_hits_prefetch, stats_num_hits_prefetch], axis=1)
    glbl_stats_num_eviction      = pd.concat([glbl_stats_num_eviction     , stats_num_eviction     ], axis=1)
    
(glbl_stats_cycle            .loc['L1D Prefetch None']/glbl_stats_cycle            ).T.plot.bar(barmode='group', title='Performance comparison with L2 without prefetching and L2 hit 100%').show()
(glbl_stats_num_prefetch     ).T.plot.bar(barmode='group', title='Number of prefetches L1D generated').show()
(glbl_stats_num_hits_prefetch.div(glbl_stats_num_prefetch).fillna(0)).T.plot.bar(barmode='group', title='Number of Prefetches Hits').show()
(glbl_stats_num_eviction     ).T.plot.bar(barmode='group', title='Number of Eviction L1D generated').show()

# %%
