#!/bin/bash
set -e

# Setup repository file in /etc/yum.repos.d
#
## Parameters:
# List of repos to enable
function add_repos() {
    local REPO=""
    for REPO in $@; do
        case "${REPO}" in
            EPEL)
                rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
                cat >/etc/yum.repos.d/epel.repo <<EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priorityenabled=1
# Django : 2014-08-14
# default: gpgcheck=0
gpgcheck=1
# default: unsetpriority = 10
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
EOF
                ;;
            docker)
                rpm --import https://download.docker.com/linux/centos/gpg
                cat >/etc/yum.repos.d/docker.repo <<EOF
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/centos/7/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
                ;;
            graphviz)
                cat >/etc/yum.repos.d/graphviz.repo <<EOF
[graphviz-stable]
name=Graphviz - RHEL $releasever - $basearch
baseurl=http://www.graphviz.org/pub/graphviz/stable/redhat/el\$releasever/\$basearch/os/
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF
                ;;
            graphviz-development)
                cat >/etc/yum.repos.d/graphviz-development.repo <<EOF
[graphviz-stable]
name=Graphviz - RHEL $releasever - $basearch
baseurl=http://www.graphviz.org/pub/graphviz/development/redhat/el\$releasever/\$basearch/os/
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF
                ;;
            IUS)
                rpm --import https://dl.iuscommunity.org/pub/ius/IUS-COMMUNITY-GPG-KEY
                cat >/etc/yum.repos.d/ius.repo <<EOF
[ius]
name=IUS Community Packages for Enterprise Linux 7 - $basearch
#baseurl=https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/\$basearch
mirrorlist=https://mirrors.iuscommunity.org/mirrorlist?repo=ius-centos7&arch=\$basearch&protocol=http
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=https://dl.iuscommunity.org/pub/ius/IUS-COMMUNITY-GPG-KEY
EOF
                ;;
            nodejs)
                yum -y install https://rpm.nodesource.com/pub_8.x/el/7/x86_64/nodesource-release-el7-1.noarch.rpm
                ;;
            elasticsearch5)
                rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
                cat >/etc/yum.repos.d/elasticsearch5.repo <<EOF
[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
                ;;
            elasticsearch6)
                rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
                cat >/etc/yum.repos.d/elasticsearch6.repo <<EOF
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
                ;;
            bareos)
                rpm --import http://download.bareos.org/bareos/release/17.2/CentOS_7/repodata/repomd.xml.key
                cat >/etc/yum.repos.d/bareos.repo <<EOF
[bareos]
name=Bareos EL7 - \$basearch
baseurl=http://download.bareos.org/bareos/release/17.2/CentOS_7/
enabled=1
gpgcheck=1
gpgkey=http://download.bareos.org/bareos/release/17.2/CentOS_7/repodata/repomd.xml.key
failovermethod=priority
EOF
                ;;
        esac
    done
}

# Generic software installation routine
#
## Parameters:
#    List of packages to install
function install_software() {
    sed -e 's/enabled=.*/enabled=0/' -i /etc/yum/pluginconf.d/fastestmirror.conf
    yum -y clean all
    yum -y --disableplugin=fastestmirror update 
    yum -y --disableplugin=fastestmirror install $@
}

# Install oracle java 8 based on environment variables
#
## Required environment:
#    JAVA_VERSION (e.g. 8u131), JAVA_BUILD_NUMBER /e.g. b11)
#    JAVA_HOME (e.g./usr/java/jdk1.8.0_131) and JAVA_DL_PATH (e.g. 
#    d54c1d3a095b4ff2b6607d096fa80163/), this is the hash part of the download
#    URL including a trailing slash (to be downwards compatible the URLs without
#    that URL component, this can be set to "")
#
## Required packages:
#    curl, unzip
function install_java8() {
    cd /tmp/
    curl -jkLsS -H "Cookie: oraclelicense=accept-securebackup-cookie" \
         "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}-${JAVA_BUILD_NUMBER}/${JAVA_DL_PATH}jdk-${JAVA_VERSION}-linux-x64.rpm" \
         -o /tmp/jdk.rpm
    curl -jkLsS -H "Cookie: oraclelicense=accept-securebackup-cookie" \
         http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip \
         -o /tmp/jce_policy-8.zip
    if [ -n "${JAVA_CHECKSUM}" ]; then
        echo "${JAVA_CHECKSUM}  /tmp/jdk.rpm" >/tmp/jdk.rpm.sha256sum
        if [ -n "${JCE_CHECKSUM}" ]; then
            echo "${JCE_CHECKSUM}  /tmp/jce_policy-8.zip" >>/tmp/jdk.rpm.sha256sum
        fi
        sha256sum -c /tmp/jdk.rpm.sha256sum
    fi
    yum -y install /tmp/jdk.rpm
    cd ${JAVA_HOME}/jre/lib/security
    unzip /tmp/jce_policy-8.zip
}

# Install oracle java 10 based on environment variables
#
## Required environment:
#    JAVA_VERSION (e.g. 10.0.1), JAVA_BUILD_NUMBER /e.g. 10)
#    JAVA_HOME (e.g./usr/java/jdk10.0.1_10) 
#
## Required packages:
#    curl, unzip
function install_java10() {
    cd /tmp/
    curl -jkLsS -H "Cookie: oraclelicense=accept-securebackup-cookie" \
         "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}+${JAVA_BUILD_NUMBER}/${JAVA_DL_PATH}/jdk-${JAVA_VERSION}_linux-x64_bin.rpm" \
         -o /tmp/jdk.rpm
    if [ -n "${JAVA_CHECKSUM}" ]; then
        echo "${JAVA_CHECKSUM}  /tmp/jdk.rpm" >/tmp/jdk.rpm.sha256sum
        sha256sum -c /tmp/jdk.rpm.sha256sum
    fi
    yum -y install /tmp/jdk.rpm
}

# Get the sudo alternative gosu and install it to /usr/local/bin
#
## Required environment variables:
#    GOSU_VERSION (e.g. 1.10)
#
## Required packages:
#    curl, gpg
function get_gosu() {
    curl -sSL https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -o /usr/local/bin/gosu 
    local GPG=$(type -p gpg)
    if [ -n "${GPG}" ]; then
        curl -sSL https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc -o /tmp/gosu.asc
        ${GPG} --keyserver keys.gnupg.net --recv-keys '0x036a9c25bf357dd4'
        ${GPG} --verify /tmp/gosu.asc /usr/local/bin/gosu
    fi
    chmod a+x /usr/local/bin/gosu
}

# Create an application user
#
## Required environment variables:
#    APP_USER (e.g. myapp)
#    APP_UID (e.g. 20000)
#    APP_GROUP ( e.g. mygroup)
#    APP_GID (e.g. 20000)
#    APP_HOME (e.g. /opt/myapp)

function create_user_and_group() {
    set +e
    grep "${APP_GROUP}:x:${APP_GID}:" /etc/group &>/dev/null
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        groupadd -g ${APP_GID} ${APP_GROUP}
    fi
    grep "${APP_USER}:x:${APP_UID}:" /etc/passwd &>/dev/null
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        useradd -c "Application user" -d ${APP_HOME} -g ${APP_GROUP} -m -s /bin/bash -u ${APP_UID} ${APP_USER}
    fi
    set -e
    if [ ! -d ${APP_HOME} ]; then
        mkdir -p ${APP_HOME}
    fi
    chown -R ${APP_USER}:${APP_GROUP} ${APP_HOME}
}

# Generic cleanup function. This uninstalls software no longer needed and cleans
# the directory /tmp/
#
## Parameters:
#    List of packages to uninstall
function cleanup() {
    if [ $# -ne 0 ]; then
        yum -y erase $@
    fi
    yum -y autoremove
    yum clean all
    set +e
    /bin/rm -rf /var/cache/yum/*
    /bin/rm /tmp/*
    chmod 777 /tmp
}

# Set proxy for yum
#
## Environment variables:
# http_proxy or https_proxy, optional proxy_username and proxy_password
#
function set_yum_proxy() {
    if [ -n "${https_proxy}" ]; then
        local PROXY="${https_proxy}"
    else
        if [ -n "${http_proxy}" ]; then
            local PROXY="${http_proxy}"
        fi
    fi
    set +e
    if [ -n "${proxy}" ]; then
        grep -e "^proxy=" /etc/yum.conf &>/dev/null
        if [ $? -eq 0 ]; then
            sed -e "s/^proxy=.*$/proxy=${proxy}" -i /etc/yum.conf
        else
            echo "proxy=${proxy}" >>/etc/yum.conf
        fi
    fi
    if [ -n "${proxy_user}" ]; then
        grep -e "^proxy_username=" /etc/yum.conf &>/dev/null
        if [ $? -eq 0 ]; then
            sed -e "s/^proxy_username=.*$/proxy_username=${proxy__username}" -i /etc/yum.conf
        else
            echo "proxy_username=${proxy_username}" >>/etc/yum.conf
        fi
    fi
    if [ -n "${proxy_password}" ]; then
        grep -e "^proxy_password=" /etc/yum.conf &>/dev/null
        if [ $? -eq 0 ]; then
            sed -e "s/^proxy_password=.*$/proxy_password=${proxy_password}" -i /etc/yum.conf
        else
            echo "proxy_password=${proxy_password}" >>/etc/yum.conf
        fi
    fi
    set -e
}


# Patch Dockerfile
function patch_dockerfile() {
    local DF=${1}
    if [ -z "${DF}" ]; then
        DF="Dockerfile"
    fi
    if [ -z "${PARENT_HISTORY}" ]; then
        local FROM=$(grep "FROM" ${DF}|sed -e 's/FROM\s*//')
        docker pull ${FROM}
        local PARENTENV=$(docker run --rm --entrypoint=/bin/bash ${FROM} -c export)
        PARENT_HISTORY=$(echo ${PARENTENV}|grep "IMAGE_HISTORY"|sed -e 's/.*IMAGE_HISTORY=//' -e 's/"//g')
    fi
    sed -e "s,GIT_COMMIT=.*\",GIT_COMMIT=\"${GIT_COMMIT}\"," \
        -e "s,IMAGE_HISTORY=.*\",IMAGE_HISTORY=\"${BUILD_TAG} « ${PARENT_HISTORY}\"," \
        -i ${DF}
}
