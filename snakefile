# snakemake v7
# snakemake --cores 32

# For now, manually delete (old) out/ directory with previous test results, or forcerun.
# This pipeline is not meant to be run completely each time, but rather to run individual rules to test specific parts during development and test



# 1) Conda latest 
# r11_download_latest             Clones git repo latest
# r12_install           Runs mamba to install fresh environments into conda_prefix
# r13_run_staticdb      Full test on static database
# r141_database          Download databases into new dir and ...
# r142_run               Full test on new databases
#
# 2) Apptainer latest
# r21_apptainer_dry     Creates a conda environment with the asscom2 launcher
# r22_run               Runs the fast or full pipeline using apptainer
#
#                       It shouldn't be necessary to test that the docker image
#                       can still download the databases.
# 
# 3) Apptainer master (release candidate)



ruleorder: r13_run_staticdb > r142_run # Because r13 is quicker.



rule all:
    input: 
        "1_done.flag",    
        "2_done.flag"




# Downloads the latest commit
# consider purging ~/.asscom2/conda if you want to test reinstallation from .yamls.
rule r11_download_latest:
    output: 
        touch("out/1_latest_conda/11_done.flag"),
        "out/1_latest_conda/assemblycomparator2-master/asscom2"
    shell: """

        # Always print versions of any dependencies outside ac2 in the start.

        mamba --version
        
        # Purge previous results
        rm -r out/1_latest_conda/*
        
        # Download latest
        wget --continue -O out/1_latest_conda/master.zip https://github.com/cmkobel/assemblycomparator2/archive/refs/heads/master.zip
        unzip -d out/1_latest_conda out/1_latest_conda/master.zip 
        #cd out/1_latest_conda/assemblycomparator2-master/

    """


# This one installs installs the package and does a dry run
rule r12_install:
    input: 
        "out/1_latest_conda/assemblycomparator2-master/asscom2"
    output:
        touch("out/1_latest_conda/12_done.flag"),
    shell: """
    
        # Save 
        fnas=$(realpath fnas/E._faecium_4)
        set_conda_prefix="$(pwd -P)/static_conda_prefix"
        
        # Enter the dir where we just downloaded latest 
        cd out/1_latest_conda/assemblycomparator2-master/
        
        # Install environment.
        conda env create -y -f environment.yaml -n asscom2_latest_test
        source activate asscom2_latest_test

        export ASSCOM2_BASE=$(pwd -P)

        # Run latest dry run
        #export ASSCOM2_BASE="$(realpath ~/asscom2)"
        export ASSCOM2_PROFILE="${{ASSCOM2_BASE}}/profile/conda/default"
        ${{ASSCOM2_BASE}}/asscom2 \
            --config \
                input_genomes="${{fnas}}/*.fna" \
        --conda-prefix $set_conda_prefix \
        --until fast \
        --dry-run


    """

# This rule does a full run on a static database.
# If you purge static_conda_prefix, you can force reinstalling the conda environments.
# Uses the same database as is already on the system.
rule r13_run_staticdb:
    input: 
        "out/1_latest_conda/assemblycomparator2-master/asscom2", 
    output: 
        touch("static_conda_prefix/yamls_done.flag"),
        touch("out/1_latest_conda/13_done.flag"),
        #"out/1_latest_conda/tests/E._faecium/results_ac2/report_E._faecium.html",
        touch("1_done.flag")
    threads: 32
    shell: """
    
        # Save 
        fnas=$(realpath fnas/E._faecium_4)
        set_conda_prefix="$(pwd -P)/static_conda_prefix"
        
        # Enter the dir where we just downloaded latest 
        cd out/1_latest_conda/assemblycomparator2-master/
        
        source activate asscom2_latest_test

        export ASSCOM2_BASE=$(pwd -P)

        # Run latest
        #export ASSCOM2_BASE="$(realpath ~/asscom2)"
        export ASSCOM2_PROFILE="${{ASSCOM2_BASE}}/profile/conda/default"
        ${{ASSCOM2_BASE}}/asscom2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
        --conda-prefix $set_conda_prefix 

    """


# Uses its own closed database.
rule r141_database:
    input:
        "out/1_latest_conda/assemblycomparator2-master/asscom2", 
        "static_conda_prefix/yamls_done.flag"
    output:
        touch("out/1_latest_conda/14_done.flag")
    threads: 6 # 6 Databases to download in parallel.
    shell: """

        cd out/1_latest_conda
        
        # Set base for ac2
        export ASSCOM2_BASE=$(pwd -P)

        # Define, clean and prepare database path
        export ASSCOM2_DATABASES="database"
        test -d $ASSCOM2_DATABASES && /usr/bin/env rm -r $ASSCOM2_DATABASES
        mkdir -p $ASSCOM2_DATABASES

        # Enter test directory
        cd tests/E._faecium

        export ASSCOM2_PROFILE=$ASSCOM2_BASE/profiles/conda/default
        snakemake \
            --snakefile $ASSCOM2_BASE/snakefile \
            --profile $ASSCOM2_PROFILE \
            --configfile $ASSCOM2_BASE/config.yaml \
            --conda-prefix $ASSCOM2_BASE/conda_prefix \
            --until downloads \
            --forcerun downloads \
            --cores {threads}

    """


rule r142_run:
    input: 
        "out/1_latest_conda/assemblycomparator2-master/asscom2", 
        "static_conda_prefix/yamls_done.flag"
    output: 
        touch("out/1_latest_conda/15_done.flag"),
        "out/1_latest_conda/tests/E._faecium/results_ac2/report_E._faecium.html",
        touch("1_done.flag")
        
    threads: 16
    shell: """

        mamba --version
        export ASSCOM2_DATABASES="database"

        cd out/1_latest_conda
        
        # Set base for ac2
        export ASSCOM2_BASE=$(pwd -P)

        # Enter test directory
        cd tests/E._faecium

        export ASSCOM2_PROFILE=$ASSCOM2_BASE/profiles/conda/default
        snakemake \
            --snakefile $ASSCOM2_BASE/snakefile \
            --profile $ASSCOM2_PROFILE \
            --configfile $ASSCOM2_BASE/config.yaml \
            --conda-prefix $ASSCOM2_BASE/conda_prefix \
            --until fast \
            --cores {threads}

    """




# 2 latest, apptainer

rule r21_apptainer_dry:
    output:
        touch("out/2_apptainer/21_done.flag"),
        touch("2_done.flag")
    shell: """
    
        apptainer --version
        mamba --version

        mamba create \
            -y \
            -c conda-forge \
            -c bioconda \
            -n assemblycomparator2-ac2-test-battery assemblycomparator2

        source activate assemblycomparator2-ac2-test-battery

        asscom2 --version

    """


rule r22_run:
    input: 
        "out/2_apptainer/21_done.flag"
    output:
        touch("out/2_apptainer/22_done.flag")
    threads: 16
    shell: """

        # Activate environment
        source activate assemblycomparator2-ac2-test-battery

        echo "Testing ac version:"
        asscom2 --version

        # Gather test fnas.
        cd out/2_apptainer
        cp ../../fnas/*.fna .

        # Run asscom2.
        #asscom2 --until fast --cores {threads}
        asscom2 --cores {threads}
        
        
    """


# In case r12 fails we should set it back to strict.
onerror:
    shell: """
        conda config --set channel_priority strict
    """
