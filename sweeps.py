from codar.cheetah import parameters as p

def create_experiment(writer_nprocs, reader_nprocs, trj_engine, sorted_trj_engine, machine_name, node_layout):
    """
    Creates a sweep object that tells Cheetah how to run the adios io test.
    Assumes 1D decomposition.
    """
    # print(adios_xml_file)
    # print(engine)
    params = [
            # ParamRunner 'nprocs' specifies the no. of ranks to be spawned 
            p.ParamRunner       ('writer', 'nprocs', [writer_nprocs]),
            # Create a ParamCmdLineArg parameter to specify a command line argument to run the application
            p.ParamCmdLineArg   ('writer', 'config', 1, ['copro.nw']),
            # Change the engine for the 'SimulationOutput' IO object in the adios xml file
            p.ParamADIOS2XML    ('writer', 'trajectory', 'trj', 'engine', [trj_engine]),
            # Sweep over four values for the nprocs 
            p.ParamRunner       ('reader', 'nprocs', [reader_nprocs]),
            p.ParamCmdLineArg   ('reader', 'input_md', 1, ['copro_md']),
            p.ParamCmdLineArg   ('reader', 'verbose', 2, [1]),
            # Change the engine for the 'SimulationOutput' IO object in the adios xml file
            p.ParamADIOS2XML    ('reader', 'sorted_trj', 'SortingOutput', 'engine', [sorted_trj_engine]),
            p.ParamRunner       ('analyzer', 'nprocs', [1]),
            p.ParamCmdLineArg   ('analyzer', 'script', 1, ['pca3d.R']),
            p.ParamCmdLineArg   ('analyzer', 'window', 2, [100]),
            p.ParamCmdLineArg   ('analyzer', 'stride', 3, [10]),
            p.ParamCmdLineArg   ('analyzer', 'k', 4, [5]),
            p.ParamCmdLineArg   ('analyzer', 'sorted_trj', 5, ['copro_md_trj.bp']),
            p.ParamCmdLineArg   ('analyzer', 'xml', 6, ['adios2.xml']),
            p.ParamCmdLineArg   ('analyzer', 'mcCore', 7, [1]),
            p.ParamCmdLineArg   ('analyzer', 'output', 8, ['pairs.pdf']),
    ]

    sweep = p.Sweep(parameters=params)
    if node_layout:
        sweep.node_layout = {machine_name: node_layout}

    return sweep

