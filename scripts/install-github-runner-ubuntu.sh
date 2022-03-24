#!/bin/bash


_GITHUB_RUNNER_VERSION='${github_runner_version}'
_GITHUB_RUNNER_REGISTRATION_TOKEN='${github_runner_registration_token}'
_GITHUB_URL='${github_url}'
_GITHUB_RUNNER_LABEL_LIST='${github_runner_label_list}'

# Install Docker
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
    apt-transport-https \
    software-properties-common \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo groupadd docker || true
sudo usermod -aG docker ubuntu
newgrp docker

cd /
mkdir -p actions-runner && cd actions-runner


arch=$(uname -m)
if [ "$arch" == "aarch64" ]; then
    arch="arm64"    
elif [ "$arch" == "x86_64" ]; then
    arch="x64"    
fi

curl -o actions-runner-linux-$arch-$_GITHUB_RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$_GITHUB_RUNNER_VERSION/actions-runner-linux-$arch-$_GITHUB_RUNNER_VERSION.tar.gz

tar xzf ./actions-runner-linux-$arch-$_GITHUB_RUNNER_VERSION.tar.gz  

chown ubuntu:ubuntu . -R

# if [ "$?" == "0" ]; then
#     echo "Finished Github Actions Runner installation"
# else
#     echo "Failed to install Github Actions Runner"
#     exit 1
# fi


# Configure runner

#sudo -E -u ubuntu sh -x config.sh --labels $_GITHUB_RUNNER_LABEL_LIST --url $_GITHUB_URL --token $_GITHUB_RUNNER_REGISTRATION_TOKEN
sudo -u ubuntu bash -x config.sh --unattended --labels $_GITHUB_RUNNER_LABEL_LIST --url $_GITHUB_URL --token $_GITHUB_RUNNER_REGISTRATION_TOKEN


if [ "$?" != "0" ]; then
    echo "########################################################################################"
    echo "--------- FAILED while running config.sh while set up Runner for $_GITHUB_URL"
    echo "########################################################################################"
    exit 1
fi

# Configuring the runner application as OS service.

bash -x svc.sh install

if [ "$?" != "0" ]; then
    echo "########################################################################################"
    echo "--------- FAILED to install Runner as OS service for $_GITHUB_URL"
    echo "########################################################################################"
    exit 1
fi

#Fix to address issue with start of the server with SELinux enabled: https://github.com/actions/runner/issues/410#issuecomment-644993319
chcon system_u:object_r:usr_t:s0 runsvc.sh

bash -x svc.sh start


if [ "$?" == "0" ]; then
  echo "########################################################################################"
  echo "--------- Finished setup of GitHub Actions Runner on $HOSTNAME"
  echo "########################################################################################"

else
  echo "########################################################################################"
  echo "--------- FAILED to set up GitHub Actions Runner on $HOSTNAME"
  echo "########################################################################################"
  exit 1
fi
