#! /bin/bash

export PYTHONPATH=$PYTHONPATH:$PWD
directory=$PROJWORK/csc143/xin/nwchem_copro_sorting_pca
touch $directory
rm -rf $directory
echo $directory
cheetah create-campaign -e rhea_campaign.py -m rhea -o $directory -a $PWD

