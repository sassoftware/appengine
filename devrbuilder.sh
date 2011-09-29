#!/bin/bash
#
# Copyright (c) 2011 rPath, Inc.
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

# Copy dev ssh key
##copy ~/id_rsa_devkey /root/.ssh/id_rsa

# Copy my known hosts to avoid asking later
copy ~/.ssh/known_hosts /root/.ssh/known_hosts

# Get the latest versions of group rbuilder
platform=$(conary rq --labels group-rpath-platform=jules.eng.rpath.com@rpath:platform-$branch-devel)
dist=$(conary rq --labels group-rbuilder-dist=jules.eng.rpath.com@rpath:rba-$branch)

cat ~/hg/rbuilder-$branch/rbuilder-system-model | sed -e "s|^search\ group-rpath-platform.*|search\ $platform|" | sed -e "s|^search\ group-rbuilder-dist.*|search\ $dist|" > /tmp/rbuilder-system-model

# Copy over the system model and update the system
copy /tmp/rbuilder-system-model /etc/conary/system-model
run echo 'updating system'
run conary updateall
run conary update vim=buildme.rb.rpath.com@rpath:buildme-2
run conary install pyflakes=buildme.rb.rpath.com@rpath:buildme-2
run conary install pyflakes-vim=buildme.rb.rpath.com@rpath:buildme-2

# Write out my hgrc
copy ~/.hgrc /root/.hgrc

# Copy vim config
copy ~/.vimrc /root/.vimrc
copy ~/.vim /root/.vim

# fclone the rBuilder forest
checkoutdir="/srv/code/products/rbuilder"
checkout="$checkoutdir/$branch"
run mkdir -p $checkoutdir
run hg fclone ssh://$USER@scc.eng.rpath.com//hg/products/rbuilder/$branch $checkout
run make -C $checkout

# reconfigure apache to run out of a checkout
echo "PythonPath \"['$checkout/include'] + sys.path\"" > /tmp/apache.conf
copy /tmp/apache.conf /etc/httpd/conf.d/rbuilder/00_include.conf

echo "export PYTHONPATH=$checkout/include" > /tmp/rbuilder.sh
copy /tmp/rbuilder.sh /etc/profile.d/rbuilder.sh

run $checkout/mint/scripts/group-script
