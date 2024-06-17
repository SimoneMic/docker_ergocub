#!/bin/bash
/home/${USER}/mambaforge/envs/ergocub/bin/pip install -r requirements.txt

/home/${USER}/mambaforge/bin/conda install habitat-sim=0.2.2 -c conda-forge -c aihabitat -y

cd ~
git clone --recursive https://github.com/cvg/Hierarchical-Localization/
cd Hierarchical-Localization/

python3 -m pip install -e .