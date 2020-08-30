from codar.cheetah import Campaign
import rhea_sweep_groups as rhea_sg

class Adios_iotest(Campaign):

    # Global campaign options
    name                    = "ADIOS_IOTEST_NWCHEM"
    codes                   = [ ("writer", dict(exe="/ccs/home/xinliang/codes/pca3d/R/adios/nwchem/bin/LINUX64/nwchem", adios_xml_file='adios2.xml')), ("reader", dict(exe="/ccs/home/xinliang/codes/pca3d/R/adios/nwchem-sort-trajectory/build/nwchem-sort-trajectory-global", adios_xml_file='adios2.xml')), ("analyzer", dict(exe="/autofs/nccs-svm1_sw/rhea/.swci/0-core/opt/spack/20191017/linux-rhel7-x86_64/gcc-6.2.0/r-4.0.0-hjogaagip3nmp6ezzgqaysuxeaoif5gd/bin/Rscript", adios_xml_file='adios2.xml'))]
    supported_machines      = ['rhea', 'theta', 'summit']
    kill_on_partial_failure = True
    run_dir_setup_script    = None
    run_post_process_script = 'post-processing/cleanup.sh'
    umask                   = '027'
    scheduler_options       = {'rhea': {'project':'csc143'}, 'theta':  {'project':'', 'queue': 'batch'}, 'summit': {'project':'csc303'}}
    app_config_scripts      = {'rhea': 'env-setup/env_setup_rhea.sh', 'theta': 'env-setup/env_setup_theta.sh', 'summit':'env-setup/env_setup_summit.sh'}

    # sweeps = {'summit': summit_sg.sweep_groups, 'local': local_sg.sweep_groups}
    sweeps = {'rhea': rhea_sg.sweep_groups}

