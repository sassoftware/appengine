#!/bin/sh
#
# Copyright (c) 2008 rPath, Inc.
# All rights reserved
#
# Get the build version for build.xml

hgDir=..
if [[ `uname` == "Linux" ]]; then
  hgPath=/usr/bin/hg
else
  hgPath=/usr/local/bin/hg
fi

if [[ -x $hgPath && -d $hgDir/.hg ]] ; then
    rev=`hg id -i`
elif [ -f $hgDir/.hg_archival.txt ]; then
    rev=`grep node $hgDir/.hg_archival.txt |cut -d' ' -f 2 |head -c 12`;
else
    rev= ;
fi ;
echo "$rev"

