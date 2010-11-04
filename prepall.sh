#!/bin/bash
cd `dirname $0`
for x in conary conary-test catalog-service mint rmake rpath-capsule-indexer rpath-models rpath-product-definition rpath-repeater rpath-storage rpath-xmllib smartform/py/smartform raa
do
    make -C $x || exit 1
done
make -C conary minimal || exit 1
