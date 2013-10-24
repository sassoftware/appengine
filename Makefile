#
# Copyright (c) rPath, Inc.
#

export PYTHON = python
export PYVER = $(shell $(PYTHON) -c 'import sys; print(sys.version[0:3])')
# These will extract the code 
CODE_VERSION = $(shell grep '^macros version ' bob-plans/config/version.conf | cut -d' ' -f3)
CODE_MAJOR = rba-$(shell grep '^macros rbuilder_forest ' bob-plans/config/version.conf | cut -d' ' -f3 | cut -d- -f1)
TAG = $(CODE_MAJOR)-$(CODE_VERSION)
BRANCH = $(notdir $(CURDIR))
site_packages = /usr/lib64/python$(PYVER)/site-packages
pth_file = $(site_packages)/devrbuilder.pth

make_dirs = \
	conary \
	conary/conary_test \
	catalog-service \
	rbuild \
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
	$(MAKE) -C mint
	( cd jobmaster && $(PYTHON) setup.py build_ext --inplace )
	$(PYTHON) -mcompileall -f `pwd`/include/*

snapshot:
	@ > substate.txt
	@for x in *; do \
		[ -d "$$x/.hg" ] || continue; \
		echo SNAPSHOT $$x; \
		[ -s "$$x/.hg/patches/status" ] && { echo $$x has patches applied, aborting; exit 1; }; \
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

install-pth:
	cp include/mungepath.py $(site_packages)/
	echo "import mungepath; mungepath.insert('$(CURDIR)/include')" > $(pth_file)
	echo "$(site_packages)/raa/vendor" >> $(pth_file)

uninstall-pth:
	rm -f $(pth_file)

update:
	[ -f /etc/conary/system-model ] || cp rbuilder-system-model /etc/conary/system-model
	sed -i \
		-e "s#^search group-rbuilder-\(dist\|appliance\)=.*#search $(shell conary rq --labels group-rbuilder-dist=newton.eng.rpath.com@rpath:rba-$(BRANCH)-rba)#" \
		-e "s#^search group-rpath-platform=.*#search $(shell conary rq --labels group-rpath-platform=newton.eng.rpath.com@rpath:rba-$(BRANCH)-platform)#" \
		/etc/conary/system-model
	conary sync
