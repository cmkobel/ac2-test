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
# 2) Apptainer stable
# r21_apptainer_dry     Creates a conda environment with the asscom2 launcher
# r22_run               Runs the fast or full pipeline using apptainer
#
#                       It shouldn't be necessary to test that the docker image
#                       can still download the databases.
# 
# 3) conda stable



report_dir = "~/PhD/19_asscom2_MS/CI_reports"




rule all:
    input: 
        "1_done.flag",    
        "2_done.flag",
        "3_done.flag",
        "4_done.flag"
        






# Latest "development" version on github (branch master)
# Reuses the default conda prefix and databases which are probably already set up on the developing machine.
rule r1_latest_reuse:
    output:
        touch("1_done.flag"),
        dir = directory("out/1_latest")
    threads: 16
    shell: """
    
    
        # Download latest.
        mkdir -p {output.dir}
        rm -r {output.dir}/* || echo "{output.dir} is already empty"
        
        wget --continue -O {output.dir}/master.zip https://github.com/cmkobel/assemblycomparator2/archive/refs/heads/master.zip
        unzip -d {output.dir} {output.dir}/master.zip 
        
        fnas=$(realpath fnas/E._faecium_4)         
        
        # Enter the dir where we just downloaded latest 
        cd {output.dir}/assemblycomparator2-master/
        
        
        ls -lh
        
        
        # Install environment.
        mamba create -y -f environment.yaml -n ac2_ci_conda_latest_reuse
        source activate ac2_ci_conda_latest


        export ASSCOM2_PROFILE="$(realpath profile/conda/default)"

        
        ./asscom2 --version
        ./asscom2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
        --until fast 
        
    """


# Same as r1 but including database downloads and fresh conda
rule r2_latest:
    output:
        touch("2_done.flag"),
        dir = directory("out/2_latest")
    threads: 16
    shell: """
    
    
        # Download latest.
        mkdir -p {output.dir}
        rm -r {output.dir}/* || echo "{output.dir} is already empty"
        
        wget --continue -O {output.dir}/master.zip https://github.com/cmkobel/assemblycomparator2/archive/refs/heads/master.zip
        unzip -d {output.dir} {output.dir}/master.zip 
        
        fnas=$(realpath fnas/E._faecium_4)         
        mkdir -p {output.dir}/conda_prefix
        set_conda_prefix=$(realpath {output.dir}/conda_prefix)
        mkdir -p {output.dir}/db
        export ASSCOM2_DATABASES="$(realpath {output.dir}/db)"
        
        # Enter the dir where we just downloaded latest 
        cd {output.dir}/assemblycomparator2-master/
        
        
        ls -lh
        
        
        # Install environment.
        mamba create -y -f environment.yaml -n ac2_ci_conda_latest
        source activate ac2_ci_conda_latest


        export ASSCOM2_PROFILE="$(realpath profile/conda/default)"

        
        ./asscom2 --version
        ./asscom2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
        --conda-prefix $set_conda_prefix \
        --until fast 
        
    
    """


rule r3_conda_stable:
    output:
        touch("3_done.flag"),
        dir = "out/3_conda_stable"        
    threads: 16
    shell: """
        
        mamba create -y -c conda-forge -c bioconda -n ac2_ci_conda_stable assemblycomparator2

        source activate ac2_ci_conda_stable
        
        asscom2 --version
            
        # Set up database
        #test -d {output.dir}/dynamic_db_stable && rm -r {output.dir}/dynamic_db_stable
        #mkdir -p {output.dir}/dynamic_db_stable
        #export ASSCOM2_DATABASES="$(realpath {output.dir}/dynamic_db_stable)"
        
        export ASSCOM2_PROFILE="$(dirname $(realpath $(which asscom2)))/profile/conda/default"
        asscom2 \
            --cores {threads} \
            --config \
                input_genomes="fnas/E._faecium_4/*.fna" \
                output_directory="{output.dir}"
    
    """
    
    
    
rule r4_apptainer:
    output:
        touch("4_done.flag"),
        dir = directory("out/4_apptainer")
    shell: """
    
        # Make sure that apptainer exists for this test.
        apptainer --version
        
        # Create conda environment.
        mamba create -y -c conda-forge -c bioconda -n ac2_ci_apptainer assemblycomparator2
        source activate ac2_ci_apptainer
        
        # Set up db
        mkdir -p {output.dir}/db
        export ASSCOM2_DATABASES=$(realpath {output.dir}/db)

        export ASSCOM2_PROFILE="$(dirname $(realpath $(which asscom2)))/profile/apptainer/default"
        which asscom2 
        asscom2 --version
        sleep 10
        asscom2 \
            --cores {threads} \
            --config \
                input_genomes="fnas/E._faecium_4/*.fna" \
                output_directory="{output.dir}"
    
        
    """



# Until I implement some smart email service this is the solution.
onsuccess:
    shell: f"""
        rm {report_dir}/ERROR.flag
        touch {report_dir}/SUCCESS.flag
    """
    
onerror:
    shell: f"""
        touch {report_dir}/ERROR.flag
        rm {report_dir}/SUCCESS.flag
    """
