#!/bin/bash
set -euo pipefail
IFS=$'\n\t'



source activate comparem2-ci

snakemake --profile profile/default --until $1 --forcerun $1

