#!/bin/bash
cd `dirname $0`
for x in catalog-service mint rpath-capsule-indexer rpath-product-definition rpath-storage rpath-xmllib
do
    make -C $x
done
make -C conary minimal
