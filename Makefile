#
# Copyright (c) 2011 rPath, Inc.
#

PYVER = $(shell python -c 'import sys; print(sys.version[0:3])')
# These will extract the code 
CODE_VERSION = $(shell grep '^macros version ' bob-plans/config/rbuilder.conf | cut -d' ' -f3)
CODE_MAJOR = $(shell grep '^targetLabel ' bob-plans/config/rbuilder.conf | cut -d':' -f2 | cut -d- -f1,2)
TAG = $(CODE_MAJOR)-$(CODE_VERSION)

make_dirs = \
	conary \
	catalog-service \
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

# These trees get tagged individually, in addition to the basic snapshot. The
# only purpose is to make it easier to diff those trees between rBuilder
# versions.
# Note: only tag trees that:
# A) are unique to rbuilder (not conary, rmake, etc.) -- this reduces tag spam
#    in public trees
# B) are moderately active, because there's no benefit if nobody actually uses
#    the tags
tag_dirs = \
	bob-plans \
	hudson \
	jobslave \
	mint \
	qa \
	rbm \
	rbuilder-ui \
	recipes \
	rpath-repeater \


all:
	for x in $(make_dirs); do $(MAKE) -C $$x || exit 1; done
	$(MAKE) -C rmake3 rmake3
	$(MAKE) -C pcreator-test replace-rpl2
	make -C mint
	python$(PYVER) -mcompileall -f `pwd`/include/*

snapshot:
	@ > substate.txt
	@for x in *; do \
		[ -d "$$x/.hg" ] || continue; \
		echo SNAPSHOT $$x; \
		hg -R "$$x" parents --template "{node} " >>substate.txt || exit 1; \
		echo "$$x" >>substate.txt; \
	done
	@echo
	@echo "Now verify substate.txt, commit, and tag:"
	@echo hg ci -m "$(CODE_VERSION)"
	@echo "hg tag $(TAG)"

tag: snapshot
	@for x in $(tag_dirs); do\
		tag=$$(awk "\$$2 == \"$$x\" {print \$$1}" substate.txt); \
		echo hg -R $$x tag -r $$tag $(TAG); \
	done
	@echo hg fpush

clean:
	for x in $(make_dirs); do $(MAKE) -C $$x clean || exit 1; done
	make -C mint clean
