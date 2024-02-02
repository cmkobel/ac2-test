# snakemake 7
# snakemake --cores 32

# For now, manually delete (old) out/ directory with previous test results.


rule all:
    input: "last.flag"


# clone master, conda
rule r11_master_conda:
    output: touch("out/1_master_conda/11_done.flag"),
        "out/1_master_conda/snakefile"
    shell: """

        # Always print versions of any dependencies outside ac2 in the start.
        git --version
        mamba --version

        # Git refuses to write to existing directories, so we must first delete the one that snakemake creates.
        /usr/bin/rm -r out/1_master_conda

        # Clone and enter
        git clone git@github.com:cmkobel/assemblycomparator2.git out/1_master_conda
        cd out/1_master_conda
        
        # Set base for ac2
        export ASSCOM2_BASE=$(pwd -P); 

        # Enter test directory
        cd tests/E._faecium

        # Dry-run
        export ASSCOM2_PROFILE=$ASSCOM2_BASE/profiles/conda/local; 
        snakemake \
            --snakefile $ASSCOM2_BASE/snakefile \
            --profile $ASSCOM2_PROFILE \
            --configfile $ASSCOM2_BASE/config.yaml \
            --dry-run

    """


#rule r12_database:
#    pass

rule r13_fast:
    input: "out/1_master_conda/snakefile"
    output: touch("out/1_master_conda/13_done.flag"),
        "out/1_master_conda/tests/E._faecium/results_ac2/report_E._faecium.html",
        touch("last.flag")
    threads: 8
    shell: """

        mamba --version

        cd out/1_master_conda
        
        # Set base for ac2
        export ASSCOM2_BASE=$(pwd -P); 

        # Enter test directory
        cd tests/E._faecium

        # Dry-run
        export ASSCOM2_PROFILE=$ASSCOM2_BASE/profiles/conda/local; 
        snakemake \
            --snakefile $ASSCOM2_BASE/snakefile \
            --profile $ASSCOM2_PROFILE \
            --configfile $ASSCOM2_BASE/config.yaml \
            --until fast \
            --cores {threads}

    """
