#!/bin/bash
set -euo pipefail
IFS=$'\n\t'



echo "Info: Expecting conda environment comparem2-ci to be activated already."

snakemake --profile profile/default --until $1 --forcerun $1

