#
# Copyright (c) 2011 rPath, Inc.
#

PYVER = $(shell python -c 'import sys; print(sys.version[0:3])')

make_dirs = \
	conary \
	conary-test \
	catalog-service \
	mint \
	rmake \
	rmake3 \
	rpath-capsule-indexer \
	rpath-models \
	rpath-product-definition \
	rpath-repeater \
	rpath-storage \
	rpath-xmllib \
	smartform/py/smartform \
	raa \

all:
	for x in $(make_dirs); do $(MAKE) -C $$x || exit 1; done
	$(MAKE) -C rmake3 rmake3
	$(MAKE) -C pcreator-test replace-rpl2
	python$(PYVER) -mcompileall -f `pwd`/include/*

snapshot:
	> substate.txt
	for x in *; do \
		[ -d "$$x/.hg" ] || continue; \
		hg -R "$$x" parents --template "{node} " >>substate.txt || exit 1; \
		echo "$$x" >>substate.txt; \
	done
	@echo
	@echo "Now verify substate.txt, commit, and tag."

clean:
	for x in $(make_dirs); do $(MAKE) -C $$x clean || exit 1; done
