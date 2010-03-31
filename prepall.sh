#!/bin/bash
cd `dirname $0`
for x in conary conary-test catalog-service mint rmake rpath-capsule-indexer rpath-product-definition rpath-storage rpath-xmllib smartform/py/smartform
do
    make -C $x
done
