PYTHON = python3
PIP = $(PYTHON) -m pip
TWINE = $(PYTHON) -m twine

SOURCE_DIR = src
PYNAUTY_VERSION = $(shell $(PYTHON) -m $(SOURCE_DIR).pynauty pynauty-version)
NAUTY_VERSION = $(shell $(PYTHON) -m $(SOURCE_DIR).pynauty nauty-version)
NAUTY_DIR = $(shell $(PYTHON) -m $(SOURCE_DIR).pynauty nauty-dir)

python_version_full := $(wordlist 2,4,$(subst ., ,$(shell $(PYTHON) --version 2>&1)))
python_version_major := $(word 1,${python_version_full})
python_version_minor := $(word 2,${python_version_full})
python_version_patch := $(word 3,${python_version_full})
platform := "$(shell uname -a)"
machine := $(shell uname -m)
LIBPATH = build/lib.linux-$(machine)-${python_version_major}.${python_version_minor}

MODULE_TEST = $(PWD)/src/module-test.py

VENV_DIR = .venv-pynauty

export

help:
	@echo Available targets:
	@echo
	@echo '  pynauty        - build the pynauty extension module'
ifdef VIRTUAL_ENV
	@echo '  tests          - run all tests loading from virtaulenv' $(VIRTUAL_ENV)
else
	@echo '  tests          - run all tests loading either from build/ or from an active virtualenv'
endif
ifdef VIRTUAL_ENV
	@echo '  install        - install pynauty into virtualenv' $(VIRTUAL_ENV)
else
	@echo '  install        - install pynauty either into ~/.local or into an active virtualenv'
endif
ifdef VIRTUAL_ENV
	@echo '  uninstall      - uninstall pynauty from virtualenv' $(VIRTUAL_ENV)
else
	@echo '  uninstall      - uninstall pynauty either from ~/.local or from an active virtualenv'
endif
	@echo '  docs           - build pyanauty documentation'
	@echo '  dist           - create a source distribution'
	@echo '  clean          - remove all files created by build/packaging except' $(VENV_DIR)/
	@echo '  clean-docs     - remove pyanauty documentation'
	@echo '  virtenv-create - create virtualenv' $(VENV_DIR)/
	@echo '  virtenv-delete - delete virtualenv' $(VENV_DIR)/
	@echo '  nauty-objects  - compile only nauty.o nautil.o naugraph.o schreier.o naurng.o'
	@echo '  clean-nauty    - a "distclean" for nauty'
	@echo '  clobber        - clean + clean-nauty + clean-docs + virtenv-delete'
	@echo
	@echo 'Pynauty version:' ${PYNAUTY_VERSION}
	@echo 'Nauty version:  ' ${NAUTY_VERSION}
	@echo 'Python version: ' ${python_version_full}
	@echo 'Pip used:       ' ${PIP}
	@echo 'Platform:       ' ${platform}

pynauty: nauty-objects
	$(PYTHON) setup.py build

.PHONY: tests
tests: pynauty
ifdef VIRTUAL_ENV
tests: install
	$(PYTHON) $(MODULE_TEST) pytest
	$(PYTHON) -m pytest 
else
	PYTHONPATH="${LIBPATH}:$(PYTHONPATH)" $(PYTHON) $(MODULE_TEST) pytest
	PYTHONPATH="${LIBPATH}:$(PYTHONPATH)" $(PYTHON) -m pytest
endif

minimal-test: pynauty
ifdef VIRTUAL_ENV
minimal-test: install
	$(PYTHON) tests/test_minimal.py
else
	PYTHONPATH="../${LIBPATH}:$(PYTHONPATH)" $(PYTHON) tests/test_minimal.py
endif

update-packaging-helpers:
ifdef VIRTUAL_ENV
	$(PIP) install --upgrade pip
	$(PIP) install --upgrade setuptools
	$(PIP) install --upgrade setuptools_scm
	$(PIP) install --upgrade setuptools_git
	$(PIP) install --upgrade wheel
	$(PIP) install --upgrade build
	$(PIP) install --upgrade twine
	$(PIP) install --upgrade auditwheel
else
	@echo using globally installed packaging helpers
endif

install: pynauty # docs
ifdef VIRTUAL_ENV
	$(PIP) install --upgrade .
else
	$(PIP) install --user --upgrade .
endif

uninstall:
	$(PIP) uninstall pynauty

.PHONY: docs
docs: pynauty
ifdef VIRTUAL_ENV
	$(PIP) install --upgrade sphinx
endif
	cd docs; make html

.PHONY: dist
dist: pynauty minimal-test docs
	make clean-nauty
	#$(PYTHON) setup.py sdist
	#$(PYTHON) setup.py bdist_wheel
	$(PYTHON) -m build
	@cd dist/ ; ../src/fix-wheel-tag.sh
	@echo Packages created:
	@ls -l dist/

upload: dist
	$(TWINE) upload --repository testpypi dist/*

clean-docs:
	cd docs; make clean

clean:
	rm -fr build
	rm -fr dist
	rm -f MANIFEST
	rm -fr tests/{__pycache__,data_graphs.pyc}
	rm -fr .pytest_cache/
	rm -fr pynauty.egg-info

virtenv-create:
	$(PYTHON) -m venv $(VENV_DIR)
	@echo Created virtualenv: $(VENV_DIR)/
	@echo To activate it type: source $(PWD)/$(VENV_DIR)/bin/activate

virtenv-delete:
	rm -fr $(VENV_DIR)
	@echo Deleted virtualenv: $(VENV_DIR)/
	@echo If it is still active, deactivate it!

clobber: clean clean-nauty clean-docs virtenv-delete

# nauty targets

nauty-config:
	cd $(SOURCE_DIR); make $@

nauty-objects:
	cd $(SOURCE_DIR); make $@

nauty-programs:
	cd $(SOURCE_DIR); make $@

clean-nauty:
	cd $(SOURCE_DIR); make $@
