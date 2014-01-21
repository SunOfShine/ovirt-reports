# ====================================================================
#
#  Licensed to the Apache Software Foundation (ASF) under one or more
#  contributor license agreements.  See the NOTICE file distributed with
#  this work for additional information regarding copyright ownership.
#  The ASF licenses this file to You under the Apache License, Version 2.0
#  (the "License"); you may not use this file except in compliance with
#  the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# ====================================================================
#
# This software consists of voluntary contributions made by many
# individuals on behalf of the Apache Software Foundation.  For more
# information on the Apache Software Foundation, please see
# <http://www.apache.org/>.

#
# CUSTOMIZATION-BEGIN
#
BUILD_UT=1
EXTRA_BUILD_FLAGS=
BUILD_VALIDATION=0

PACKAGE_NAME=ovirt-engine-reports
MVN=mvn
PYTHON=python
PYFLAKES=pyflakes
PEP8=pep8
PREFIX=/usr/local
LOCALSTATE_DIR=$(PREFIX)/var
BIN_DIR=$(PREFIX)/bin
SYSCONF_DIR=$(PREFIX)/etc
DATAROOT_DIR=$(PREFIX)/share
MAN_DIR=$(DATAROOT_DIR)/man
DOC_DIR=$(DATAROOT_DIR)/doc
PKG_DATA_DIR=$(DATAROOT_DIR)/ovirt-engine-reports
JAVA_DIR=$(DATAROOT_DIR)/java
PKG_JAVA_DIR=$(JAVA_DIR)/ovirt-engine-reports
PKG_SYSCONF_DIR=$(SYSCONF_DIR)/ovirt-engine-reports
PKG_JBOSS_MODULES=$(PKG_DATA_DIR)/modules
PKG_CACHE_DIR=$(LOCALSTATE_DIR)/cache/ovirt-engine-reports
PKG_LOG_DIR=$(LOCALSTATE_DIR)/log/ovirt-engine-reports
PKG_TMP_DIR=$(LOCALSTATE_DIR)/tmp/ovirt-engine-reports
PKG_STATE_DIR=$(LOCALSTATE_DIR)/lib/ovirt-engine-reports
JBOSS_HOME=/usr/share/jboss-as
PYTHON_DIR=$(PYTHON_SYS_DIR)
DEV_PYTHON_DIR=
PKG_USER=ovirt
PKG_GROUP=ovirt
#
# CUSTOMIZATION-END
#

include version.mak
# major, minor, seq
POM_VERSION:=$(shell cat pom.xml | grep '<ovirt-reports.version>' | sed -e 's/.*>\(.*\)<.*/\1/' -e 's/-SNAPSHOT//')
# major, minor from pom and fix
APP_VERSION=$(shell echo $(POM_VERSION) | sed 's/\([^.]*\.[^.]\)\..*/\1/').$(FIX_RELEASE)
RPM_VERSION=$(APP_VERSION)
PACKAGE_VERSION=$(APP_VERSION)$(if $(MILESTONE),_$(MILESTONE))
DISPLAY_VERSION=$(PACKAGE_VERSION)


BUILD_FLAGS:=
ifeq ($(BUILD_UT),0)
BUILD_FLAGS:=$(BUILD_FLAGS) -D skipTests
endif
BUILD_FLAGS:=$(BUILD_FLAGS) $(EXTRA_BUILD_FLAGS)

PYTHON_SYS_DIR:=$(shell $(PYTHON) -c "from distutils.sysconfig import get_python_lib as f;print(f())")
OUTPUT_DIR=output
TARBALL=$(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.gz
ARCH=noarch
BUILD_FILE=tmp.built
MAVEN_OUTPUT_DIR=.
BUILD_TARGET=install

ARTIFACTS = \
	ChartsCustomizers \
	EngineAuthentication \
	ReportsLineBarChartTheme \
	ReportsPieChartTheme \
	ReportsStatus \
	WebadminLineBarChartTheme \
	CustomOvirtReportsQueryManipulator \
	$(NULL)

.SUFFIXES:
.SUFFIXES: .in

.in:
	sed \
	-e "s|@PKG_USER@|$(PKG_USER)|g" \
	-e "s|@PKG_GROUP@|$(PKG_GROUP)|g" \
	-e "s|@DATAROOT_DIR@|$(DATAROOT_DIR)|g" \
	-e "s|@PKG_SYSCONF_DIR@|$(PKG_SYSCONF_DIR)|g" \
	-e "s|@PKG_DATA_DIR@|$(PKG_DATA_DIR)|g" \
	-e "s|@PKG_LOG_DIR@|$(PKG_LOG_DIR)|g" \
	-e "s|@PKG_STATE_DIR@|$(PKG_STATE_DIR)|g" \
	-e "s|@PKG_JBOSS_MODULES@|$(PKG_JBOSS_MODULES)|g" \
	-e "s|@JBOSS_HOME@|$(JBOSS_HOME)|g" \
	-e "s|@DEV_PYTHON_DIR@|$(DEV_PYTHON_DIR)|g" \
	-e "s|@DWH_VARS@|$(PKG_SYSCONF_DIR)/ovirt-engine-reportsd.conf|g" \
	-e "s|@RPM_VERSION@|$(RPM_VERSION)|g" \
	-e "s|@RPM_RELEASE@|$(RPM_RELEASE)|g" \
	-e "s|@PACKAGE_NAME@|$(PACKAGE_NAME)|g" \
	-e "s|@PACKAGE_VERSION@|$(PACKAGE_VERSION)|g" \
	-e "s|@DISPLAY_VERSION@|$(DISPLAY_VERSION)|g" \
	-e "s|@PEP8@|$(PEP8)|g" \
	-e "s|@PYFLAKES@|$(PYFLAKES)|g" \
	$< > $@

GENERATED = \
	build/python-check.sh \
	ovirt-engine-reports.spec \
	packaging/jasper-customizations/WEB-INF/applicationContext-ovirt-override.xml \
	packaging/jasper-customizations/WEB-INF/log4j.properties \
	packaging/sys-etc/ovirt-engine/engine.conf.d/50-ovirt-engine-reports.conf \
	$(NULL)

all:	\
	generated-files \
	validations \
	$(BUILD_FILE) \
	$(NULL)

generated-files:	$(GENERATED)
	chmod a+x build/python-check.sh

$(BUILD_FILE):
	export MAVEN_OPTS="${MAVEN_OPTS} -XX:MaxPermSize=512m"
	$(MVN) \
		$(BUILD_FLAGS) \
		$(BUILD_TARGET) \
		$(NULL)
	touch $(BUILD_FILE)

clean:
	$(MVN) clean $(EXTRA_BUILD_FLAGS)
	rm -rf $(OUTPUT_DIR) $(BUILD_FILE) tmp.dev.flist
	rm -rf $(GENERATED)

test:
	$(MVN) install $(BUILD_FLAGS) $(EXTRA_BUILD_FLAGS)

install: \
	all \
	install-artifacts \
	install-layout \
	$(NULL)

.PHONY: ovirt-engine-reports.spec.in

dist:	ovirt-engine-reports.spec
	git ls-files | tar --files-from /proc/self/fd/0 -czf "$(TARBALL)" ovirt-engine-reports.spec
	@echo
	@echo For distro specific packaging refer to http://www.ovirt.org/Build_Binary_Package
	@echo

# copy SOURCEDIR to TARGETDIR
# exclude EXCLUDEGEN a list of files to exclude with .in
# exclude EXCLUDE a list of files.
copy-recursive:
	( cd "$(SOURCEDIR)" && find . -type d -printf '%P\n' ) | while read d; do \
		install -d -m 755 "$(TARGETDIR)/$${d}"; \
	done
	( \
		cd "$(SOURCEDIR)" && find . -type f -printf '%P\n' | \
		while read f; do \
			exclude=false; \
			for x in $(EXCLUDE_GEN); do \
				if [ "$(SOURCEDIR)/$${f}" = "$${x}.in" ]; then \
					exclude=true; \
					break; \
				fi; \
			done; \
			for x in $(EXCLUDE); do \
				if [ "$(SOURCEDIR)/$${f}" = "$${x}" ]; then \
					exclude=true; \
					break; \
				fi; \
			done; \
			$${exclude} || echo "$${f}"; \
		done \
	) | while read f; do \
		src="$(SOURCEDIR)/$${f}"; \
		dst="$(TARGETDIR)/$${f}"; \
		[ -x "$${src}" ] && MASK=0755 || MASK=0644; \
		[ -n "$(DEV_FLIST)" ] && echo "$${dst}" | sed 's#^$(PREFIX)/##' >> "$(DEV_FLIST)"; \
		install -T -m "$${MASK}" "$${src}" "$${dst}"; \
	done

validations:	generated-files
	if [ "$(BUILD_VALIDATION)" != 0 ]; then \
		build/shell-check.sh && \
		build/python-check.sh; \
	fi

install-artifacts:
	install -d "$(DESTDIR)$(PKG_JAVA_DIR)"
	for artifact_id in $(ARTIFACTS); do \
		JAR=`find "$(MAVEN_OUTPUT_DIR)" -name "$${artifact_id}-*.jar" | grep -v tmp.repos`; \
		install -p -m 644 "$${JAR}" "$(DESTDIR)$(PKG_JAVA_DIR)/$${artifact_id}.jar"; \
	done

install-packaging-files: \
		$(GENERATED) \
		$(NULL)
	$(MAKE) copy-recursive SOURCEDIR=packaging/sys-etc TARGETDIR="$(DESTDIR)$(SYSCONF_DIR)" EXCLUDE_GEN="$(GENERATED)"
	for d in conf jasper-customizations ovirt-reports legacy-setup; do \
		$(MAKE) copy-recursive SOURCEDIR="packaging/$${d}" TARGETDIR="$(DESTDIR)$(PKG_DATA_DIR)/$${d}" EXCLUDE_GEN="$(GENERATED)"; \
	done

install-layout: \
		install-packaging-files \
		$(NULL)

	install -dm 755 "$(DESTDIR)$(PKG_SYSCONF_DIR)/ovirt-engine-reports.conf.d"
	install -dm 755 "$(DESTDIR)$(BIN_DIR)"
	ln -sf ovirt_reports_bundle_en_US.properties.data "$(DESTDIR)$(PKG_DATA_DIR)/ovirt-reports/resources/reports_resources/localization/ovirt_reports_bundle.properties.data"
	ln -sf "$(PKG_DATA_DIR)/legacy-setup/ovirt-engine-reports-setup.py" "$(DESTDIR)$(BIN_DIR)/ovirt-engine-reports-setup"

all-dev:
	rm -f $(GENERATED)
	$(MAKE) \
		all \
		DEV_PYTHON_DIR="$(PREFIX)$(PYTHON_SYS_DIR)" \
		$(NULL)

install-dev:	\
		all-dev \
		$(NULL)

	if [ -f "$(DESTDIR)$(PREFIX)/dev.$(PACKAGE_NAME).flist" ]; then \
		cat "$(DESTDIR)$(PREFIX)/dev.$(PACKAGE_NAME).flist" | while read f; do \
			rm -f "$(DESTDIR)$(PREFIX)/$${f}"; \
		done; \
		rm -f "$(DESTDIR)$(PREFIX)/dev.$(PACKAGE_NAME).flist"; \
	fi

	rm -f tmp.dev.flist
	$(MAKE) \
		install \
		BUILD_VALIDATION=0 \
		PYTHON_DIR="$(PREFIX)$(PYTHON_SYS_DIR)" \
		DEV_FLIST=tmp.dev.flist \
		$(NULL)
	cp tmp.dev.flist "$(DESTDIR)$(PREFIX)/dev.$(PACKAGE_NAME).flist"

	install -d "$(DESTDIR)$(PKG_LOG_DIR)"
	install -d "$(DESTDIR)$(PKG_STATE_DIR)"
