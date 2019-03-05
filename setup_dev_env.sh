#!/bin/bash

GO_VERSION=1.12
DOCKER_COMPOSE_VERSION=1.23.2
DOCKER_VERSION=18.09.3

OS_TYPE=$(cat /etc/os-release|grep -E "^ID="|sed -e 's|.*=||'|tr '[:upper:]' '[:lower:]')


function install_required() {
    local APP=$1
    local VERSION=$2
    local INSTALL=0
    type -f ${APP} &>/dev/null
    if [ $? -ne 0 ]; then
        INSTALL=1
    else
        if [ "${APP}" == "docker" ]; then
            local INSTALLED_VERSION=$($APP version|grep "Version:" |awk '{print $2}'|tail -1)
        else
            local INSTALLED_VERSION=$(${APP} version |awk '{print $3}'|sed -e 's|,||')
        fi
    if [ "${INSTALLED_VERSION}" < "${VERSION}" ]; then
        INSTALL=1
    else
        INSTALL=0
    fi
    return INSTALL
fi
}

install_required go ${GO_VERSION}
INSTALL_GO=$?
if [ ${INSTALL_GO} -ne 0 ]; then
    curl -o /tmp/go.tar.gz https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
fi

install_required docker-compose ${DOCKER_COMPOSE_VERSION}
INSTALL_DOCKER_COMPOSE=$?
if [ ${INSTALL_DOCKER_COMPOSE} -ne 0 ]; then
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /tmp/docker-compose
fi

install_required docker ${DOCKER_VERSION}
INSTALL_DOCKER=$?


# ------ sudo required

if [ ${INSTALL_GO} -ne 0 ]; then
    if [ -d /usr/local/go ]; then
        sudo /bin/rm -rf /usr/local/go
    fi
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    sudo cat >/etc/profile.d/golang.sh <<EOF
GOPATH="$HOME/go"
PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"
export GOPATH PATH
EOF
    /bin/rm /tmp/go.tar.gz
fi

if [ ${INSTALL_DOCKER_COMPOSE} -ne 0 ]; then
   sudo /bin/mv /tmp/docker-compose /usr/local/bin/docker-compose
fi

if [ ${INSTALL_DOCKER} -ne 0 ]; then
    case "${OS_TYPE}" in
        ubuntu,debian)
            curl -fsSL https://download.docker.com/linux/${OS_TYPE}/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${OS_TYPE} $(lsb_release -cs) stable"
            sudo apt-get update
            sudo apt-get install docker-ce docker-ce-cli containerd.io
            ;;
        centos,rhel,fedora)
            sudo curl -o /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install docker-ce docker-ce-cli containerd.io
            ;;
        *)
            echo "Please install docker-ce manually"
            ;;
    esac
fi
