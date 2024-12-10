#!/bin/bash

conda_path="/home/thylakoid/miniforge3/bin/conda"


datetime="$(date)"

echo $datetime initialized > ~/ci_datetime.log

cd /mnt/evo/comparem2-ci

#${conda_path} activate comparem2-ci
source ~/miniforge3/bin/activate /home/thylakoid/miniforge3/envs/comparem2-ci

echo $datetime started >> ~/ci_datetime.log

snakemake --profile profile/default --until conda_latest_reuse

echo $datetime ended >> ~/ci_datetime.log

