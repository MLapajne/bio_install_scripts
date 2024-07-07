#!/bin/bash

#export DEBIAN_FRONTEND=noninteractive
#echo "tzdata tzdata/Areas select Europe" | debconf-set-selections
#echo "tzdata tzdata/Zones/Europe select Ljubljana" | debconf-set-selections

command_exists() {
    command -v "$1" >/dev/null 2>&1
}
#export PATH="/root/miniconda3/bin/:$PATH"

# Define a function to verify the installation of a given command
verify_installation() {
    local cmd=$1
    echo "Verifying the $cmd installation..."
    if [ "$cmd" == "spades" ]; then
        cmd="spades.py"
    elif [ "$cmd" == "dbcan" ]; then
        cmd="run_dbcan"
    elif [ "$cmd" == "bioconductor-dada2" ]; then
        cmd="Rscript -e 'library(\"dada2\")'"
    fi
    if command_exists "$cmd"; then
        echo "$cmd has been installed successfully."
        echo "You can run $cmd using the command: $cmd"
    else
        echo "$cmd installation failed. Please check the output for details."
        exit 1
    fi
}

create_and_activate_env() {
    local env_name=$1
    # Check if the environment already exists
    if conda info --envs | grep -qw "$env_name"; then
        echo "Environment '$env_name' already exists. Activating it."
    else
        echo "Creating environment '$env_name'."
        conda create -y -n "$env_name" python=3.8
    fi
    # Source conda command and activate environment
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "$env_name"
}

function install_and_activate_tool() {
    local tool_name=$1
    local env_name=$2
    local special_command=$3

    cd $HOME
    if ! command_exists "$tool_name"; then
        create_and_activate_env "$env_name"

        # Add the bioconda channel
        conda config --add channels conda-forge
        conda config --add channels bioconda

        conda install -y "$tool_name"
        if [[ -n "$special_command" ]]; then
            eval "$special_command"
        fi
        verify_installation "$tool_name"
    else
        echo "$tool_name is already installed and activated."
        conda activate "$env_name"
    fi
}


# Check if conda is installed
if ! command_exists conda; then
    echo "Conda is required but not installed. Installing Miniconda..."
    #apt-get update && apt-get install -y wget
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi

	wget --quiet $MINICONDA_URL -O ~/miniconda3_installer.sh
    bash ~/miniconda3_installer.sh -b -p $HOME/miniconda3 && rm ~/miniconda3_installer.sh && echo "Miniconda3 installation completed......"
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
    conda init
    source ~/.bashrc
else
    echo "Conda is already installed"
fi

case "$1" in
    "spades")
        install_and_activate_tool "spades" "env_spades"
        ;;
    "flye")
        install_and_activate_tool "flye" "env_flye"
        ;;
    "unicycler")
        install_and_activate_tool "unicycler" "env_unicycler" 
        ;;
    "bakta")
        install_and_activate_tool "bakta" "env_bakta"
        ;;
    "antismash")
        install_and_activate_tool "antismash" "env_antismash" "download-antismash-databases"
        ;;
    "dbcan")
        install_and_activate_tool "dbcan" "env_dbcan" "dbcan_build --cpus 8 --db-dir db --clean"
        ;;
    "barrnap")
        install_and_activate_tool "barrnap" "env_barrnap"
        ;;
    "dada2")
        install_and_activate_tool "bioconductor-dada2" "env_dada2"
        ;;
        #used in R language, include like that: library("dada2")
    *)
        echo "Unsupported tool: $1"
        ;;
esac

# Install the required packages
: '
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install(version = "3.19")

if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("dada2", version = "3.11")
'

: '
curl -s https://get.nextflow.io | bash
#chmod +x nextflow
mv nextflow /usr/local/bin/
git clone https://github.com/bioinfo-pf-curie/vegan.git
cd vegan
git lfs install
git lfs pull
'
#singularity
: '
sudo apt-get update && \
    sudo apt-get install -y \
    dh-autoreconf \
    build-essential \
    libarchive-dev

wget -O- http://neuro.debian.net/lists/jammy.de-fzj.full |  tee /etc/apt/sources.list.d/neurodebian.sources.list
sudo apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9
sudo apt-get update
sudo apt-get install -y singularity-container
'
