#!/bin/bash
cd `dirname $0`
for x in conary conary-test catalog-service mint rmake rpath-capsule-indexer rpath-models rpath-product-definition rpath-repeater rpath-storage rpath-xmllib smartform/py/smartform raa
do
    make -C $x || exit 1
done
make -C conary minimal || exit 1
make -C rmake3 all rmake3 || exit 1
make -C pcreator-test replace-rpl2 || exit 1
python -mcompileall -f `pwd`/include/*
