# snakemake 7
# snakemake --cores 32

# For now, manually delete (old) out/ directory with previous test results.


rule all:
    input: 
        "1_done.flag",    
        "2_done.flag"


# 1 master, conda "development"

# consider purging ~/.asscom2/conda if you want to test reinstallation from .yamls.
rule r11_clone:
    output: 
        touch("out/1_master_conda/11_done.flag"),
        "out/1_master_conda/snakefile"
    shell: """

        # Always print versions of any dependencies outside ac2 in the start.
        git --version
        mamba --version

        # Git refuses to write to existing directories, so we must first delete the one that snakemake creates.
        /usr/bin/rm -rf out/1_master_conda

        # Clone and enter
        git clone git@github.com:cmkobel/assemblycomparator2.git out/1_master_conda
        cd out/1_master_conda
        
        # Set base for ac2
        export ASSCOM2_BASE=$(pwd -P)

        # Enter test directory
        cd tests/E._faecium

        # Dry-run
        export ASSCOM2_PROFILE=$ASSCOM2_BASE/profiles/conda/local; 
        snakemake \
            --snakefile $ASSCOM2_BASE/snakefile \
            --profile $ASSCOM2_PROFILE \
            --configfile $ASSCOM2_BASE/config.yaml \
            --conda-prefix $ASSCOM2_BASE/conda_prefix \
            --dry-run

    """

# This one installs the conda .yamls into out/1_master_conda/conda_prefix. 
rule r12_install:
    input: 
        "out/1_master_conda/snakefile"
    output:
        touch("out/1_master_conda/12_done.flag"),
        touch("out/1_master_conda/conda_prefix/yamls_OK.flag")
    shell: """

        conda config --set channel_priority false

        cd out/1_master_conda
        
        # Set base for ac2
        export ASSCOM2_BASE=$(pwd -P)

        # Enter test directory
        cd tests/E._faecium

        export ASSCOM2_PROFILE=$ASSCOM2_BASE/profiles/conda/local
        snakemake \
            --snakefile $ASSCOM2_BASE/snakefile \
            --profile $ASSCOM2_PROFILE \
            --configfile $ASSCOM2_BASE/config.yaml \
            --conda-prefix $ASSCOM2_BASE/conda_prefix \
            --until sequence_lengths

        # running rule sequence_lengths is just a dummy to force it to install the conda .yamls.

        conda config --set channel_priority strict

    """

# Uses its own closed database.
rule r13_database:
    input:
        "out/1_master_conda/conda_prefix/yamls_OK.flag"
    output:
        "out/1_master_conda/13_done.flag"
    shell: """

        cd out/1_master_conda
        
        # Set base for ac2
        export ASSCOM2_BASE=$(pwd -P)

        export ASSCOM2_DATABASE="out/database"
        mkdir -p $ASSCOM2_DATABASE

        # Enter test directory
        cd tests/E._faecium

        export ASSCOM2_PROFILE=$ASSCOM2_BASE/profiles/conda/local
        snakemake \
            --snakefile $ASSCOM2_BASE/snakefile \
            --profile $ASSCOM2_PROFILE \
            --configfile $ASSCOM2_BASE/config.yaml \
            --conda-prefix $ASSCOM2_BASE/conda_prefix \
            --until sequence_lengths

    """


rule r14_run:
    input: 
        "out/1_master_conda/snakefile", 
        "out/1_master_conda/conda_prefix/yamls_OK.flag"
    output: 
        touch("out/1_master_conda/14_done.flag"),
        "out/1_master_conda/tests/E._faecium/results_ac2/report_E._faecium.html",
        "1_done.flag"
        
    threads: 16
    shell: """

        mamba --version

        cd out/1_master_conda
        
        # Set base for ac2
        export ASSCOM2_BASE=$(pwd -P)

        export ASSCOM2_DATABASE="out/database"
        mkdir -p $ASSCOM2_DATABASE

        # Enter test directory
        cd tests/E._faecium

        export ASSCOM2_PROFILE=$ASSCOM2_BASE/profiles/conda/local
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

        mamba create -y -c conda-forge -c bioconda -n assemblycomparator2-ac2-test-battery assemblycomparator2

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
