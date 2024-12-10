# CompareM2-CI

I'm drafting a simple workflow that checks that the latest version of CompareM2 works well. Should run at least weekly with e.g. cron.


These tests will run daily/weekly/monthly to test that everything is always OK.


## Usage


```bash
mamba env create -f environment.yaml

mamba activate comparem2-ci

# snakemake --profile profile/default --until all
snakemake --profile profile/default --until conda_latest_reuse
# snakemake --profile profile/default --until conda_latest
# snakemake --profile profile/default --until conda_stable
# snakemake --profile profile/default --until apptainer

```
