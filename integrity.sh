#!/bin/bash

set -euo pipefail
set -x

# Clean up potential old outputs.
[ -d results_ac2 ] && /usr/bin/rm -r results_ac2
[ -d scripts_temporary ] && /usr/bin/rm -r scripts_temporary


# Check versions and get stats
which mamba
mamba --version

which apptainer
apptainer version

apptainer cache list
du -sh ~/.asscom2

# Install ac2
mamba create -y -c conda-forge -c bioconda -n asscom2_test assemblycomparator2=2.5.14 # TODO set to patch 17

source activate asscom2_test

which asscom2


# Copy in test files
echo $CONDA_PREFIX

cp $CONDA_PREFIX/assemblycomparator2/tests/MAGs/*.fasta .


# Run comprehensive?? test
asscom2 --until fast

exit_code=$?

echo $exit_code


# Assert that outputs are corret
exit $exit_code