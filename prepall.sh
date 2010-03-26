#!/bin/bash
cd `dirname $0`
for x in catalog-service mint rpath-capsule-indexer rpath-product-definition rpath-storage rpath-xmllib rmake conary
do
    make -C $x
done
