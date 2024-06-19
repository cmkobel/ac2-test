# mamba activate comparem2-ci
# snakemake --profile profile/default --until all
# snakemake --profile profile/default --until latest_reuse
# snakemake --profile profile/default --until latest
# snakemake --profile profile/default --until conda_stable
# snakemake --profile profile/default --until apptainer

# Two types of errors:
# 1) Those that I impose upon erroneous addition of new functionality and tweaks
# 2) Those that come from upstream changes in updated conda environments. These are only prone to happen in the non-apptainer runs, hence the apptainer mostly tests the database download.

report_dir = "~/PhD/19_asscom2_MS/CI_reports"


rule all:
    input: 
        "1_done.flag", # latest_reuse
        "2_done.flag", # latest
        "3_done.flag", # conda_stable
        "4_done.flag", # apptainer
        



# Latest "development" version on github (branch master)
# Reuses the default conda prefix and databases which are probably already set up on the developing machine.
rule latest_reuse:
    output:
        touch("1_done.flag"),
        dir = directory("out/1_latest_reuse")
    threads: 16
    shell: """
    
        # Download latest.
        mkdir -p {output.dir}
        rm -r {output.dir}/* || echo "{output.dir} is already empty"
        
        wget --continue -O {output.dir}/master.zip https://github.com/cmkobel/comparem2/archive/refs/heads/master.zip
        unzip -d {output.dir} {output.dir}/master.zip 
        
        fnas=$(realpath fnas/E._faecium_4)         
        
        # Enter the dir where we just downloaded latest 
        cd {output.dir}/CompareM2-master/
        
        
        ls -lh
        
        
        # Install environment.
        mamba env create -y -f environment.yaml -n ac2_ci_conda_latest_reuse
        source activate ac2_ci_conda_latest_reuse


        export COMPAREM2_PROFILE="$(realpath profile/conda/default)"

        
        ./comparem2 --version
        ./comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" 
        
    """


# Same as r1 but including database downloads and fresh conda
rule latest:
    output:
        touch("2_done.flag"),
        dir = directory("out/2_latest")
    threads: 16
    shell: """
    
    
        # Prepare output directory
        mkdir -p {output.dir}
        rm -r {output.dir}/* || echo "{output.dir} is already empty"
        
        # Download latest
        wget --continue -O {output.dir}/master.zip https://github.com/cmkobel/assemblycomparator2/archive/refs/heads/master.zip
        unzip -d {output.dir} {output.dir}/master.zip 
        
        # Set up variables.
        fnas=$(realpath fnas/E._faecium_4)         
        mkdir -p {output.dir}/conda_prefix
        set_conda_prefix=$(realpath {output.dir}/conda_prefix)
        mkdir -p {output.dir}/db
        export COMPAREM2_DATABASES="$(realpath {output.dir}/db)"
        
        # Enter the dir where we just downloaded latest 
        cd {output.dir}/CompareM2-master/
        
        ls -lh
        
        # Install environment.
        mamba env create -y -f environment.yaml -n ac2_ci_conda_latest
        source activate ac2_ci_conda_latest

        export COMPAREM2_PROFILE="$(realpath profile/conda/default)"

        ./comparem2 --version
        
        # First call downloads
        ./comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
        --conda-prefix $set_conda_prefix \
        --until downloads
    
        # Then the complete pipeline
        ./comparem2 --version
        ./comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
        --conda-prefix $set_conda_prefix 
    
    """


rule conda_stable:
    output:
        touch("3_done.flag"),
        dir = directory("out/3_conda_stable")
    threads: 16
    shell: """
        
        mamba create -y -c conda-forge -c bioconda -n cm2_ci_conda_stable comparem2

        source activate cm2_ci_conda_stable
        
        comparem2 --version
            
        # Set up database
        #test -d {output.dir}/dynamic_db_stable && rm -r {output.dir}/dynamic_db_stable
        #mkdir -p {output.dir}/dynamic_db_stable
        #export COMPAREM2_DATABASES="$(realpath {output.dir}/dynamic_db_stable)"
        
        # Set up variables. 
        mkdir -p {output.dir}/conda_prefix
        set_conda_prefix=$(realpath {output.dir}/conda_prefix)
        mkdir -p {output.dir}/db
        export COMPAREM2_DATABASES="$(realpath {output.dir}/db)"
        
        export COMPAREM2_PROFILE="$(dirname $(realpath $(which comparem2)))/profile/conda/default"
        
        # First downloads
        comparem2 \
            --cores {threads} \
            --config \
                input_genomes="fnas/E._faecium_4/*.fna" \
                output_directory="{output.dir}" \
            --conda-prefix $set_conda_prefix \
            --until downloads
            
        # Then everything
        comparem2 \
            --cores {threads} \
            --config \
                input_genomes="fnas/E._faecium_4/*.fna" \
                output_directory="{output.dir}" \
            --conda-prefix $set_conda_prefix 
            
        
    
    """
    
    
    
rule apptainer:
    output:
        touch("4_done.flag"),
        dir = directory("out/4_apptainer")
    threads: 16
    shell: """
    
        # Make sure that apptainer exists for this test.
        apptainer --version
        
        # Create conda environment.
        mamba create -y -c conda-forge -c bioconda -n cm2_ci_apptainer comparem2
        source activate cm2_ci_apptainer
        
        # Set up db
        mkdir -p {output.dir}/db
        export COMPAREM2_DATABASES=$(realpath {output.dir}/db)

        export COMPAREM2_PROFILE="$(dirname $(realpath $(which comparem2)))/profile/apptainer/default"
        which comparem2 
        comparem2 --version
        
        comparem2 \
            --cores {threads} \
            --config \
                input_genomes="fnas/E._faecium_4/*.fna" \
                output_directory="{output.dir}" \
            --until downloads
                
        comparem2 \
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
