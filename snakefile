# mamba activate comparem2-ci
# snakemake --profile profile/default --until all
# snakemake --profile profile/default --until latest_reuse
# snakemake --profile profile/default --until latest
# snakemake --profile profile/default --until conda_stable
# snakemake --profile profile/default --until apptainer

# Two types of errors:
# 1) Those that I impose upon erroneous addition of new functionality and tweaks
# 2) Those that come from upstream changes in updated conda environments. These are only prone to happen in the non-apptainer runs, hence the apptainer mostly tests the database download.

import socket


hostname = socket.gethostname()
report_dir = "~/PhD/19_CompareM2_MS/CI_reports/" + hostname



print("report_dir:", report_dir)


rule all:
    input: 
        "0_done.flag", # fast
        "1_done.flag", # latest_reuse
        "2_done.flag", # latest
        "3_done.flag", # conda_stable
        "4_done.flag", # apptainer
        

# --- conda ---------------------------------------------------------

# 0)
# Like latest_reuse but only fast
rule conda_latest_reuse_fast:
    output:
        flag = "0_done.flag",
        dir = directory("out/0_fast")
    threads: 16
    shell: """
    
        # Prepare output directory.
        mkdir -p {output.dir}
        rm -r {output.dir}/* || echo "{output.dir} is already empty"
        
        # Download latest.
        wget --continue -O {output.dir}/master.zip https://github.com/cmkobel/comparem2/archive/refs/heads/master.zip
        unzip -d {output.dir} {output.dir}/master.zip 
        
        # Set up variables.
        fnas=$(realpath fnas/E._faecium_4)         
                
        # Setup environment.
        mamba env create -y -f {output.dir}/CompareM2-master/environment.yaml -n ac2_ci_fast
        source activate ac2_ci_fast
        export COMPAREM2_PROFILE="$(realpath {output.dir}/CompareM2-master/profile/conda/default)"
        
        {output.dir}/CompareM2-master/comparem2 --version
        {output.dir}/CompareM2-master/comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
                output_directory="{output.dir}" \
                title="fast" \
            --until fast 
            
        echo $(date) > {output.flag}
        
        echo SUCCESSFULLY COMPLETED {rule}
        
    """

# 1)
# Latest "development" version on github (branch master)
# Reuses the default conda prefix and databases which are probably already set up on the developing machine.
rule conda_latest_reuse:
    output:
        flag = "1_done.flag",
        dir = directory("out/1_latest_reuse")
    threads: 16
    shell: """
    
        # Prepare output directory.
        mkdir -p {output.dir}
        rm -r {output.dir}/* || echo "{output.dir} is already empty"
        
        # Download latest.
        wget --continue -O {output.dir}/master.zip https://github.com/cmkobel/comparem2/archive/refs/heads/master.zip
        unzip -d {output.dir} {output.dir}/master.zip 
        
        # Set up variables.
        fnas=$(realpath fnas/E._faecium_4)         
                
        # Setup environment
        mamba env create -y -f {output.dir}/CompareM2-master/environment.yaml -n ac2_ci_conda_latest_reuse
        source activate ac2_ci_conda_latest_reuse
        export COMPAREM2_PROFILE="$(realpath {output.dir}/CompareM2-master/profile/conda/default)"

        {output.dir}/CompareM2-master/comparem2 --version
        {output.dir}/CompareM2-master/comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
                output_directory="{output.dir}" \
            --until fast
                
        {output.dir}/CompareM2-master/comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
                output_directory="{output.dir}" \
                title="latest_reuse" 
                
        echo $(date) > {output.flag}
        
        echo SUCCESSFULLY COMPLETED {rule}
        
    """

# 2)
# Same as "latest_reuse" but including database downloads and fresh conda
rule conda_latest:
    output:
        flag = "2_done.flag",
        dir = directory("out/2_latest")
    threads: 16
    shell: """
    
        # Prepare output directory.
        mkdir -p {output.dir}
        rm -r {output.dir}/* || echo "{output.dir} is already empty"
        
        # Download latest.
        wget --continue -O {output.dir}/master.zip https://github.com/cmkobel/comparem2/archive/refs/heads/master.zip
        unzip -d {output.dir} {output.dir}/master.zip 
        
        
        # Set up variables.
        fnas=$(realpath fnas/E._faecium_4)
        mkdir -p {output.dir}/conda_prefix
        set_conda_prefix=$(realpath {output.dir}/conda_prefix)
        mkdir -p {output.dir}/db
        export COMPAREM2_DATABASES="$(realpath {output.dir}/db)"    
                
        # Install environment.
        mamba env create -y -f {output.dir}/CompareM2-master/environment.yaml -n ac2_ci_conda_latest_reuse
        source activate ac2_ci_conda_latest_reuse
        export COMPAREM2_PROFILE="$(realpath {output.dir}/CompareM2-master/profile/conda/default)"
        
        {output.dir}/CompareM2-master/comparem2 --version
        
        
        {output.dir}/CompareM2-master/comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
                output_directory="{output.dir}" \
                title="latest_reuse" \
            --until fast \
            --conda-prefix $set_conda_prefix 
        
        
        {output.dir}/CompareM2-master/comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
                output_directory="{output.dir}" \
                title="latest_reuse" \
            --conda-prefix $set_conda_prefix 
        
        echo $(date) > {output.flag}
                
        echo SUCCESSFULLY COMPLETED {rule}
    
    """

# 3)
rule conda_stable: # aka release
    output:
        flag = "3_done.flag",
        dir = directory("out/3_conda_stable")
    threads: 16
    shell: """
        
        mamba create -y -c conda-forge -c bioconda -n cm2_ci_conda_stable comparem2

        source activate cm2_ci_conda_stable
        
        comparem2 --version
        
        # Set up variables. 
        mkdir -p {output.dir}/conda_prefix
        set_conda_prefix=$(realpath {output.dir}/conda_prefix)
        mkdir -p {output.dir}/db
        export COMPAREM2_DATABASES="$(realpath {output.dir}/db)"
        export COMPAREM2_PROFILE="$(dirname $(realpath $(which comparem2)))/profile/conda/default"
        
        comparem2 \
            --cores {threads} \
            --config \
                input_genomes="fnas/E._faecium_4/*.fna" \
                output_directory="{output.dir}" \
                title="conda_stable" \
            --conda-prefix $set_conda_prefix 
            
            
        echo $(date) > {output.flag}
            
        echo SUCCESSFULLY COMPLETED {rule}    
    
    """
    
# --- Apptainer -----------------------------------------------------

# 4
#rule apptainer_latest_fast:

# 5
#rule apptainer_latest: #aka release


# 6)
rule apptainer_stable:
    output:
        flag = "4_done.flag",
        dir = directory("out/4_apptainer")
    threads: 16
    shell: """
    
        # Make sure that apptainer exists for this test.
        apptainer --version
    
        # Prepare output directory.
        mkdir -p {output.dir}
        rm -r {output.dir}/* || echo "{output.dir} is already empty"

        # Set up variables.
        fnas=$(realpath fnas/E._faecium_4) 
        
        # Setup environment
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
                input_genomes="${{fnas}}/*.fna" \
                output_directory="{output.dir}" \
                title="apptainer" \
            --until fast
            
        echo FAST SUCCESSFULLY FINISHED
        
        comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
                output_directory="{output.dir}" \
                title="apptainer" \
            --until downloads
                
        comparem2 \
            --cores {threads} \
            --config \
                input_genomes="${{fnas}}/*.fna" \
                output_directory="{output.dir}" \
                title="apptainer" \
            --omit-from antismash
            
        # Antismash unfortunately does not work on apptainer yet, so I'm omitting it from this CI run.
        
        echo $(date) > {output.flag}
        
        echo SUCCESSFULLY COMPLETED {rule}
        
    """




# Communicate the completion somehow.

final = f"""mkdir -p {report_dir}; test -f "{report_dir}/*.flag" && rm -rf "{report_dir}/*.flag"; cp -rf *_done.flag {report_dir}; ls {report_dir}"""

onsuccess:
    shell(final)
    
onerror:
    shell(final)
