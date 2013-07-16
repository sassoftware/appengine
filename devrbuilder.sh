#!/bin/bash
#
# Copyright (c) SAS Institute
#
# Simple script to convert an rbuilder to running out of a checkout and
# install any needed dev tools.
#

if [ ! $# -eq 2 ] ; then
    echo "usage: $0 <hostname> <rbuilder branch>"
    exit 1
fi

hostname=$1
branch=$2

local_checkout=$(dirname $0)

function run() {
    ssh -A root@$hostname "$*"
    rc=$?
    if [ "$rc" != "0" ] ; then
        echo "command failed: $*"
        exit 1
    fi
    return $rc
}

function copy() {
    source=$1
    dest=$2
    scp -r $source root@$hostname:$dest
    rc=$?
    if [ "$rc" != "0" ] ; then
        echo "copy failed: $*"
        exit 1
    fi
    return $rc
}

# Deploy my ssh key
ssh-copy-id root@$hostname

# Copy my known hosts to avoid asking later
copy ~/.ssh/known_hosts /root/.ssh/known_hosts

# Get the latest versions of group rbuilder
platform=$(conary rq --labels group-rpath-platform=newton.eng.rpath.com@rpath:platform-$branch-devel)
dist=$(conary rq --labels group-rbuilder-dist=newton.eng.rpath.com@rpath:rba-$branch-rba)

tmpcnyconf=$(mktemp)
cat << EOF >$tmpcnyconf
proxyMap 10.0.0.0/8 DIRECT
proxyMap 172.16.0.0/12 DIRECT
proxyMap 192.168.0.0/16 DIRECT
proxyMap * conarys://rbuilder.unx.sas.com
proxyMap * conary://rbuilder.unx.sas.com
proxyMap * http://inetgw.fyi.sas.com
EOF

copy $tmpcnyconf /etc/conary/config.d/httpProxy

cat $local_checkout/rbuilder-system-model | sed -e "s|^search\ group-rpath-platform.*|search\ $platform|" | sed -e "s|^search\ group-rbuilder-dist.*|search\ $dist|" > /tmp/rbuilder-system-model

# Configure conary to use rbuilder.unx as a proxy
run "echo 'includeConfigFile http://delphi.unx.sas.com/conaryrc' > /etc/conary/config.d/proxy"

# Copy over the system model and update the system
copy /tmp/rbuilder-system-model /etc/conary/system-model
run echo 'updating system'
run conary updateall

# Write out my hgrc
copy ~/.hgrc /root/.hgrc

# Copy vim config
copy ~/.vimrc /root/.vimrc
copy ~/.vim /root/.vim

# fclone the rBuilder forest
checkoutdir="/srv/code/products/rbuilder"
checkout="$checkoutdir/$branch"
run mkdir -p $checkoutdir
run hg fclone ssh://$USER@scc.unx.sas.com//hg/products/rbuilder/$branch $checkout
run make -C $checkout
run make -C $checkout install-pth

# Setup python config
if [ -f ~/.pystartup ] ; then
    copy ~/.pystartup /root/.pystartup
    run 'echo "export PYTHONSTARTUP=$HOME/.pystartup" >> /root/.bashrc'
fi

run $checkout/mint/scripts/group-script
