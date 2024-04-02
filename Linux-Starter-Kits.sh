#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 <parameter>"
    echo "Parameters:"
    echo "  -h  Display this help message"
    echo "  remove-docker  Remove Docker and its related packages"
    echo "  install-docker  Install Docker and its related packages"
    echo "  install-OpenProject  Setup OpenProject"
    echo "  install-Ollama  Run Ollama installation script"
    echo "  install-network-tool  Install network tools"
    echo "  install-ssh-tool  Install tmux"
    echo "  install-aws-CLI  Install AWS CLI"
    echo "  install-git  Install git"
    echo "  install-nginx  Install Nginx Web Server"
    echo "  install-python  Install python"
    echo "  install-samba Install samba default user:root password:1111"
    echo "  install-redmine Install redmine"  
    echo "  install-iptables Install iptables" 
}

# Check if the script is run with a parameter
if [ -z "$1" ]; then
    usage
    exit 1
fi

# Check the parameter provided
if [ "$1" = "-h" ]; then
    usage
    exit 0
elif [ "$1" = "remove-docker" ]; then
    # Execute the command to remove Docker
    sudo yum remove docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine
elif [ "$1" = "install-docker" ]; then
    # Execute the command to install Docker
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
elif [ "$1" = "install-OpenProject" ]; then
    # Execute the commands to setup OpenProject
    sudo yum update
    git clone https://github.com/opf/openproject-deploy --depth=1 --branch=stable/13 openproject
    cd openproject/compose
    docker-compose pull
    OPENPROJECT_HTTPS=false docker-compose up -d
elif [ "$1" = "install-Ollama" ]; then
    # Execute the command to run Ollama installation script
    curl -fsSL https://ollama.com/install.sh | sh
    # Execute the command to run Ollama web UI container
    docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
elif [ "$1" = "install-network-tool" ]; then
    # Execute the command to install network tools
    sudo yum install -y net-tools bind-utils
    sudo yum install tcpdump -y
elif [ "$1" = "install-ssh-tool" ]; then
    # Execute the command to install tmux
    sudo yum install -y tmux
elif [ "$1" = "install-aws-cli" ]; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
elif [ "$1" = "install-git" ]; then
    sudo yum update
    sudo yum install git -y
elif [ "$1" = "install-nginx" ]; then
    sudo docker pull nginx
elif [ "$1" = "install-python" ]; then
    sudo yum install wget
    yum install gcc yum-utils zlib-devel python-tools cmake git pkgconfig -y --skip-broken
    yum groupinstall -y "Development Tools" --skip-broken
    wget https://www.python.org/ftp/python/3.12.2/Python-3.12.2.tgz
    tar xzf Python-3.12.2.tgz
    cd Python-3.12.2
    ./configure
    make
    make install
    python3 --version
    cd ..
    rm -rf Python-3.12.2
    rm -rf Python-3.12.2.tgz

elif [ "$1" = "install-samba" ]; then
    sudo yum update -y
    sudo yum install samba samba-client samba-common -y
    echo -e "1111\n1111"|sudo pdbedit -a root
    sudo bash -c 'cat > /etc/samba/smb.conf' << EOF
[global]
    workgroup = WORKGROUP
    netbios name = centos
    server string = centos
    log file = /var/log/samba/log.%m
    security = user
	log level=3
	max log size=0
    passdb backend = tdbsam
	follow symlinks = yes
	wide links = yes
	strict locking = no
	unix extensions = no
[homes]
    comment = Home Directories
    browseable = No
    path = %H
    writable = yes
    create mode = 0664
    directory mode = 0775
[ROOTGROUP]
    path = /
    browseable = yes
    writable = yes
    create mode = 0777
    directory mode = 2777
    write list = root, @root
EOF
    sudo service smb start
    sudo service nmb start
    sudo systemctl enable nmb
    sudo systemctl enable smb
    # Check if SELinux is enabled
    if [ -f /etc/selinux/config ]; then
        # Temporarily set SELinux to permissive mode
        setenforce 0   
        # Modify the SELINUX directive in the configuration file to disabled
        sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config    
        echo "SELinux disabled. Reboot your system for changes to take effect."
    else
        echo "SELinux is not enabled on this system."
    fi
elif [ "$1" = "install-redmine" ]; then
    docker pull redmine
elif [ "$1" = "install-iptables" ]; then
    sudo iptables-save > /path/to/backup-file
    sudo iptables-restore < /etc/iptables/rules.v4
else
    echo "Unknown parameter: $1"
    usage
    exit 1
fi

exit 0
