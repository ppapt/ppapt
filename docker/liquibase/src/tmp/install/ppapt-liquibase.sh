#!/bin/bash
set -e
set -x

source /tmp/install/functions.sh

install_software postgresql mariadb
curl -sskLo /tmp/wait4port.rpm https://github.com/joernott/wait4port/releases/download/v0.1.0/wait4port-0.1.0-2.x86_64.rpm
yum -y install /tmp/wait4port.rpm
cleanup
