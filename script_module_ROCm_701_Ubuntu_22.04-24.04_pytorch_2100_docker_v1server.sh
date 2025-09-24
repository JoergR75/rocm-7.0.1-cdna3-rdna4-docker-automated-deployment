#!/bin/bash
# ================================================================================================================
# ROCm 7.0.1 + OpenCL 2.x + PyTorch 2.10.0 (Nightly) + Transformers + Docker Setup
# Compatible with Ubuntu 22.04.x and 24.04.x (Desktop & Server) — Ubuntu 20.04.x is no longer supported
# ================================================================================================================
# Description:
# This script automates the installation of AMD ROCm 7.0.1, PyTorch 2.10.0 (nightly build), Transformers, and Docker
# on Ubuntu 22.04.x and 24.04.x systems. It automatically fetches the appropriate installation scripts and performs
# a fully non-interactive setup optimized for both desktop and server environments.
# ================================================================================================================
#
# REQUIREMENTS:
# ---------------------------------------------------------------------------------------------------------------
# Operating System (OS):
#   - Ubuntu 22.04.5 LTS (Jammy Jellyfish)
#   - Ubuntu 24.04.2 LTS (Noble Numbat)
#
# Kernel Versions Tested:
#   - Ubuntu 22.04: 5.15.0-144
#   - Ubuntu 24.04: 6.8.0-84
#
# Supported Hardware:
#   - AMD CDNA2 | CDNA3 | RDNA3 | RDNA4 GPU Architectures
#
# SOFTWARE VERSIONS:
# ---------------------------------------------------------------------------------------------------------------
# ROCm Platform:         7.0.1
# ROCm Release Notes:    https://rocm.docs.amd.com/en/docs-7.0.1/about/release-notes.html
# ROCm Driver Repo:      https://repo.radeon.com/amdgpu-install/7.0.1/ubuntu/
#
# PyTorch:               2.10.0.dev20250922+rocm6.4
# Transformers:          4.56.2
# Docker:                28.4.0 (latest stable release)
#
# INCLUDED TOOLS:
# ---------------------------------------------------------------------------------------------------------------
#   - git                 → Version control system for tracking changes
#   - git-lfs             → Git Large File Storage for handling large datasets & binaries
#   - cmake               → Cross-platform build system for compiling and packaging software
#   - htop                → Interactive process monitoring tool
#   - ncdu                → NCurses Disk Usage analyzer for efficient storage management
#   - libmsgpack-dev      → Development package for MessagePack (binary serialization format)
#   - freeipmi-tools      → Utilities for querying BMC firmware versions and IPMI functions
#   - rocm-bandwidth-test → Utility to measure and validate host↔GPU and inter-GPU memory bandwidth
#
# EXECUTION DETAILS:
# ---------------------------------------------------------------------------------------------------------------
# Author:                Joerg Roskowetz
# Estimated Runtime:     ~15 minutes (depending on system performance and internet speed)
# Last Updated:          September 24, 2025
# ================================================================================================================

# global stdout method
function print () {
    printf "\033[1;36m\t$1\033[1;35m\n"; sleep 4
}

clear &&
print '\nROCm 7.0.1 + OpenCL 2.x + PyTorch 2.10.0 (Nightly) + Transformers + Docker Setup\nCompatible with Ubuntu 22.04.x and 24.04.x (Desktop & Server) — Ubuntu 20.04.x is no longer supported\n'
print '\nUbuntu OS Update ...\n'

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade

print '\nDone\n'

install_focal() {
    print '\nUbuntu 20.04.x (focal) is not longer be supported for ROCm 7.0.1. The last supported version is ROCm 6.4.0.\n'
    print 'More details can be verified under https://repo.radeon.com/amdgpu-install/6.4/ubuntu/ \n'
}

install_jellyfish() {
    print '\nUbuntu 22.04.x (jammy jellyfish) installation method has been set.\n'
    # Download the installer script
    wget https://repo.radeon.com/amdgpu-install/7.0.1/ubuntu/jammy/amdgpu-install_7.0.1.70001-1_all.deb
    # install latest headers and static library files necessary for building C++ programs which use libstdc++
    sudo DEBIAN_FRONTEND=noninteractive apt install "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)" --yes
    sudo DEBIAN_FRONTEND=noninteractive apt install python3-setuptools python3-wheel libpython3.10 --yes
    sudo DEBIAN_FRONTEND=noninteractive apt install libstdc++-12-dev --yes
    sudo DEBIAN_FRONTEND=noninteractive apt install git-lfs --yes

    # Install with "default" settings (no interaction)
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ./amdgpu-install_7.0.1.70001-1_all.deb

    # Installing multiple use cases including ROCm 7.0.1, OCL and HIP SDK

    print '\nInstalling ROCm 7.0.1 + OCL 2.x environment ...\n'

    sudo apt update
    sudo apt install amdgpu-dkms rocm --yes

    # Groups setup and ROCm/OCL path in global *.icd file
    # Add path into global amdocl64*.icd file

    echo "/opt/rocm/lib/libamdocl64.so" | sudo tee /etc/OpenCL/vendors/amdocl64*.icd

    # add the user to the sudo group (iportant e.g. to compile vllm, flashattention in a pip environment)

    sudo usermod -a -G video,render ${SUDO_USER:-$USER}
    sudo usermod -aG sudo ${SUDO_USER:-$USER}

    # Install tools - git, htop, cmake, libmsgpack-dev, ncdu (NCurses Disk Usage utility / df -h) and freeipmi-tools (BMC version read)

    source ~/.bashrc
    sudo DEBIAN_FRONTEND=noninteractive apt install -y git
    sudo DEBIAN_FRONTEND=noninteractive apt install -y htop
    sudo DEBIAN_FRONTEND=noninteractive apt install -y freeipmi-tools
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ncdu
    sudo DEBIAN_FRONTEND=noninteractive apt install -y cmake
    sudo DEBIAN_FRONTEND=noninteractive apt install -y libmsgpack-dev
    sudo DEBIAN_FRONTEND=noninteractive apt install -y rocm-bandwidth-test

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc

    print '\nInstalling Pytorch 2.10.0, Transformers environment ...\n'

    pip3 install --upgrade pip
    pip3 install --upgrade pip wheel
    pip3 install joblib
    pip3 install setuptools_scm
    pip3 install --pre torch torchvision --index-url https://download.pytorch.org/whl/nightly/rocm6.4
    pip3 install transformers
    pip3 install accelerate
    pip3 install -U diffusers
    pip3 install protobuf
    pip3 install sentencepiece
    pip3 install datasets

}

install_noble() {
    print '\nUbuntu 24.04.x (noble numbat) installation method has been set.\n'
    # Download the installer script
    wget https://repo.radeon.com/amdgpu-install/7.0.1/ubuntu/noble/amdgpu-install_7.0.1.70001-1_all.deb
    # Install the necessary headers and static library files
    sudo DEBIAN_FRONTEND=noninteractive apt install "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)" --yes
    sudo DEBIAN_FRONTEND=noninteractive apt install python3-setuptools python3-wheel libpython3.12 --yes
    sudo DEBIAN_FRONTEND=noninteractive apt install libstdc++-13-dev --yes
    sudo DEBIAN_FRONTEND=noninteractive apt install git-lfs --yes

    # Install with "default" settings (no interaction)
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ./amdgpu-install_7.0.1.70001-1_all.deb

    # Installing multiple use cases including ROCm 7.0.1, OCL and HIP SDK

    print '\nInstalling ROCm 7.0.1 + OCL 2.x environment ...\n'

    sudo apt update
    sudo apt install amdgpu-dkms rocm --yes

    # Groups setup and ROCm/OCL path in global *.icd file
    # Add path into global amdocl64*.icd file

    echo "/opt/rocm/lib/libamdocl64.so" | sudo tee /etc/OpenCL/vendors/amdocl64*.icd

    # add the user to the sudo group (iportant e.g. to compile vllm, flashattention in a pip environment)

    sudo usermod -a -G video,render ${SUDO_USER:-$USER}
    sudo usermod -aG sudo ${SUDO_USER:-$USER}

    # Install tools - git, htop, cmake, libmsgpack-dev, ncdu (NCurses Disk Usage utility / df -h) and freeipmi-tools (BMC version read)

    source ~/.bashrc
    sudo DEBIAN_FRONTEND=noninteractive apt install -y git
    sudo DEBIAN_FRONTEND=noninteractive apt install -y htop
    sudo DEBIAN_FRONTEND=noninteractive apt install -y freeipmi-tools
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ncdu
    sudo DEBIAN_FRONTEND=noninteractive apt install -y cmake
    sudo DEBIAN_FRONTEND=noninteractive apt install -y libmsgpack-dev
    sudo DEBIAN_FRONTEND=noninteractive apt install -y rocm-bandwidth-test

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc

    print '\nInstalling Pytorch 2.10.0, Transformers environment ...\n'

    pip3 install --upgrade pip --break-system-packages
    pip3 install --upgrade pip wheel --break-system-packages
    pip3 install joblib --break-system-packages
    pip3 install setuptools_scm --break-system-packages
    pip3 install --pre torch torchvision --index-url https://download.pytorch.org/whl/nightly/rocm6.4 --break-system-packages
    pip3 install transformers --break-system-packages
    pip3 install accelerate --break-system-packages
    pip3 install -U diffusers --break-system-packages
    pip3 install protobuf --break-system-packages
    pip3 install sentencepiece --break-system-packages
    pip3 install datasets --break-system-packages

}

# Check if supported Ubuntu release exists
if command -v lsb_release > /dev/null; then
    UBUNTU_CODENAME=$(lsb_release -c -s)

    if [ "$UBUNTU_CODENAME" = "focal" ]; then
        print '\nDetected Ubuntu Focal Fossa (20.04.x).\n'

install_focal

    elif [ "$UBUNTU_CODENAME" = "jammy" ]; then
        print '\nDetected Ubuntu Jammy Jellyfish (22.04.x).\n'

install_jellyfish

 elif [ "$UBUNTU_CODENAME" = "noble" ]; then
        print '\nDetected Ubuntu Noble Numbat (24.04.x).\n'

install_noble

    else
        print '\nUnknown Ubuntu version!\n'
    fi
else
    print '\nlsb_release command not found. Unable to determine Ubuntu version.\n'
fi

echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# create test script
cd ~
cat <<EOF > test.py
import torch

print("PyTorch version:", torch.__version__)
print("ROCm version:", torch.version.hip if hasattr(torch.version, 'hip') else "Not ROCm build")
print("Is ROCm available:", torch.version.hip is not None)
print("Number of GPUs:", torch.cuda.device_count())
print("GPU Name:", torch.cuda.get_device_name(0) if torch.cuda.device_count() > 0 else "No GPU detected")

# Create two tensors and add them on the GPU
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

a = torch.rand(3, 3, device=device)
b = torch.rand(3, 3, device=device)
c = a + b

print("Tensor operation successful on:", device)
print(c)
EOF

# Install Docker enviroment
print '\nInstalling and configuring a Docker environment (stable version) with required dependencies and the official Docker repository, installs Docker Engine and Docker Compose and configures user permissions to allow non-root access\n'

# Update your package list
sudo apt update

# Install required dependencies
sudo apt install apt-transport-https ca-certificates curl software-properties-common --yes

# Add the Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable Docker repository
echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io --yes

# Add your user to the "docker" group (optional, to run Docker without "sudo")
sudo usermod -a -G docker ${SUDO_USER:-$USER}

# Verify the Docker installation
docker --version

# Restart Docker
sudo service docker restart 

# Final installation message
printf "\n Finished ROCm 7.0.1 + OCL 2.x + PyTorch 2.10.0 (nightly build) + Transformers + Docker environment installation and setup.\n"

# Post-reboot testing instructions
printf "\nAfter the reboot, test your installation with:\n"
printf "  • rocminfo\n"
printf "  • clinfo\n"
printf "  • rocm-smi\n"
printf "  • rocm-bandwidth-test\n"

# PyTorch verification
printf "\nVerify the active PyTorch device:\n"
printf "  python3 test.py\n"

# vLLM Docker images for RDNA4 and CDNA3
printf "\nInstall the latest vLLM Docker images:\n"
printf "  RDNA4 → sudo docker pull rocm/vllm-dev:open-r9700-08052025\n"
printf "  CDNA3 → sudo docker pull rocm/vllm:latest\n"

# Run the Docker container
printf "\nStart the vLLM Docker container:\n"
printf "  sudo docker run -it --device=/dev/kfd --device=/dev/dri \\
    --security-opt seccomp=unconfined --group-add video rocm/vllm\n"

printf "\nThe container will run using the image 'rocm/vllm', with flags enabling AMD GPU access via ROCm.\n\n"

# reboot option
print 'Reboot system now (recommended)? (y/n)'
read q
if [ $q == "y" ]; then
    for i in 3 2 1
    do
        printf "Reboot in $i ...\r"; sleep 1
    done
    sudo reboot
fi
