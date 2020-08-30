#!/bin/bash

#module load gcc
#export PATH=/ccs/home/xinliang/utils/tau/x86_64/bin:$PATH
module load gcc/6.2.0
module load rdma-core
module load openblas/0.3.9-omp
module load openmpi
export LD_PRELOAD=${OLCF_OPENBLAS_ROOT}/lib/libopenblas.so
module load r/4.0.0-py3
module load hdf5
module load python
export OMP_NUM_THREADS=4
export PCA3D_HOME=/ccs/home/xinliang/codes/pca3d
export R_LIBS=${PCA3D_HOME}/R/adios/rlib
export PATH=/ccs/home/xinliang/codes/pca3d/R/adios/tau-2.29/install/x86_64/bin:$PATH

