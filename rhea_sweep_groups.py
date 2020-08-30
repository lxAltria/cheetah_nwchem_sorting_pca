from summit_node_layouts import summit_node_layouts
from create_sweep_groups import create_sweep_groups

# Parameters
writer_np               = [224]
# reader_np               = [1, 2, 4, 8, 16]
# trj_engines             = [ {'SST':{}} ]
# sorted_trj_engines      = [ {'BP4':{'OpenTimeoutSecs':'30.0', 'BurstBufferPath':'/tmp'}} ]
reader_np               = [2]
trj_engines             = [ {'BP4':{'OpenTimeoutSecs':'30.0'}} ]
sorted_trj_engines      = [ {'BP4':{'OpenTimeoutSecs':'30.0'}} ]
components              = ['copro.nw', 'copro.top', 'copro_md.rst', 'pca3d.R', 'rpca.R']
run_repetitions         = 0
batch_job_timeout_secs  = 36600
per_experiment_timeout  = 3600


# node_layouts = summit_node_layouts('writer', 'reader')
node_layouts = []

sweep_groups = create_sweep_groups ('rhea',
                                    components,
                                    writer_np,
                                    reader_np,
                                    trj_engines,
                                    sorted_trj_engines,
                                    node_layouts,
                                    run_repetitions,
                                    batch_job_timeout_secs,
                                    per_experiment_timeout)


