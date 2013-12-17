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

include version.mak
# major, minor, seq
POM_VERSION:=$(shell cat pom.xml | grep '<ovirt-reports.version>' | sed -e 's/.*>\(.*\)<.*/\1/' -e 's/-SNAPSHOT//')
# major, minor from pom and fix
APP_VERSION=$(shell echo $(POM_VERSION) | sed 's/\([^.]*\.[^.]\)\..*/\1/').$(FIX_RELEASE)
RPM_VERSION=$(APP_VERSION)
PACKAGE_VERSION=$(APP_VERSION)$(if $(MILESTONE),_$(MILESTONE))
PACKAGE_NAME=ovirt-engine-reports
DISPLAY_VERSION=$(PACKAGE_VERSION)

MVN=mvn
EXTRA_BUILD_FLAGS=
BUILD_FLAGS=
OVIRT_REPORTS_NAME=$(PACKAGE_NAME)
PREFIX=/usr/local
BIN_DIR=$(PREFIX)/bin
SYSCONF_DIR=$(PREFIX)/etc
DATAROOT_DIR=$(PREFIX)/share
DATA_DIR=$(DATAROOT_DIR)/$(OVIRT_REPORTS_NAME)
MAVENPOM_DIR=$(DATAROOT_DIR)/maven-poms
JAVA_DIR=$(DATAROOT_DIR)/java
PKG_SYSCONF_DIR=$(SYSCONF_DIR)/ovirt-engine
PKG_JAVA_DIR=$(JAVA_DIR)/$(OVIRT_REPORTS_NAME)
RPMBUILD=rpmbuild
PYTHON=python
PYTHON_DIR:=$(shell $(PYTHON) -c "from distutils.sysconfig import get_python_lib as f;print(f())")

SPEC_FILE_IN=packaging/ovirt-engine-reports.spec.in
SPEC_FILE=$(PACKAGE_NAME).spec
OUTPUT_RPMBUILD=$(shell pwd -P)/tmp.rpmbuild
OUTPUT_DIR=output
TARBALL=$(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.gz
SRPM=$(OUTPUT_DIR)/$(PACKAGE_NAME)-$(RPM_VERSION)*.src.rpm
ARCH=noarch
BUILD_FILE=tmp.built
MAVEN_OUTPUT_DIR_DEFAULT=$(shell pwd -P)/tmp.repos
MAVEN_OUTPUT_DIR=$(MAVEN_OUTPUT_DIR_DEFAULT)

ARTIFACTS = \
            ChartsCustomizers \
            EngineAuthentication \
            ReportsLineBarChartTheme \
            ReportsPieChartTheme \
            WebadminLineBarChartTheme \
            CustomOvirtReportsQueryManipulator \
            $(NULL)

all: $(BUILD_FILE)

$(BUILD_FILE):
	export MAVEN_OPTS="${MAVEN_OPTS} -XX:MaxPermSize=512m"
	$(MVN) \
		$(BUILD_FLAGS) \
		$(EXTRA_BUILD_FLAGS) \
		dependency:resolve-plugins
	$(MVN) \
		$(BUILD_FLAGS) \
		$(EXTRA_BUILD_FLAGS) \
		-D skipTests \
		-D altDeploymentRepository=install::default::file://$(MAVEN_OUTPUT_DIR) \
		deploy
	touch $(BUILD_FILE)

clean:
	$(MVN) clean $(EXTRA_BUILD_FLAGS)
	rm -rf $(OUTPUT_RPMBUILD) $(SPEC_FILE) $(OUTPUT_DIR) $(BUILD_FILE)
	[ "$(MAVEN_OUTPUT_DIR_DEFAULT)" = "$(MAVEN_OUTPUT_DIR)" ] && rm -fr "$(MAVEN_OUTPUT_DIR)"

test:
	$(MVN) install $(BUILD_FLAGS) $(EXTRA_BUILD_FLAGS)

install: \
         all \
         install_artifacts \
         install_files  \
         $(NULL)

# legacy
tarball:	dist
dist:
	sed \
	    -e 's/@PACKAGE_NAME@/$(PACKAGE_NAME)/g' \
	    -e 's/@PACKAGE_VERSION@/$(PACKAGE_VERSION)/g' \
	    -e 's/@RPM_VERSION@/$(RPM_VERSION)/g' \
            -e 's/@RPM_RELEASE@/$(RPM_RELEASE)/g' \
	    $(SPEC_FILE_IN) > $(SPEC_FILE)
	git ls-files | tar --files-from /proc/self/fd/0 -czf $(TARBALL) $(SPEC_FILE)
	rm -f $(SPEC_FILE)
	@echo
	@echo You can use $(RPMBUILD) -tb $(TARBALL) to produce rpms
	@echo

srpm:	dist
	rm -rf $(OUTPUT_RPMBUILD)
	mkdir -p $(OUTPUT_RPMBUILD)/{SPECS,RPMS,SRPMS,SOURCES,BUILD,BUILDROOT}
	mkdir -p $(OUTPUT_DIR)
	$(RPMBUILD) -ts --define="_topdir $(OUTPUT_RPMBUILD)" $(TARBALL)
	mv $(OUTPUT_RPMBUILD)/SRPMS/*.rpm $(OUTPUT_DIR)
	rm -rf $(OUTPUT_RPMBUILD)
	@echo
	@echo srpm is ready at $(OUTPUT_DIR)
	@echo

rpm:	srpm
	rm -rf $(OUTPUT_RPMBUILD)
	mkdir -p $(OUTPUT_RPMBUILD)/{SPECS,RPMS,SRPMS,SOURCES,BUILD,BUILDROOT}
	mkdir -p $(OUTPUT_DIR)
	$(RPMBUILD) --define="_topdir $(OUTPUT_RPMBUILD)" $(RPMBUILD_EXTRA_ARGS) --rebuild $(SRPM)
	mv $(OUTPUT_RPMBUILD)/RPMS/$(ARCH)/*.rpm $(OUTPUT_DIR)
	rm -rf $(OUTPUT_RPMBUILD)
	@echo
	@echo rpms are ready at $(OUTPUT_DIR)
	@echo

install_artifacts:
	install -dm 755 $(DESTDIR)$(PKG_JAVA_DIR)
	install -dm 755 $(DESTDIR)$(MAVENPOM_DIR)

	for artifact_id in  $(ARTIFACTS); do \
		POM=`find "$(MAVEN_OUTPUT_DIR)" -name "$${artifact_id}-*.pom"`; \
		if ! [ -f "$${POM}" ]; then \
			echo "ERROR: Cannot find artifact $${artifact_id}"; \
			exit 1; \
		fi; \
		JAR=`echo "$${POM}" | sed 's/\.pom/.jar/'`; \
		install -p -m 644 "$${POM}" "$(DESTDIR)$(MAVENPOM_DIR)/$(PACKAGE_NAME)-$${artifact_id}.pom"; \
		[ -f "$${JAR}" ] && install -p -m 644 "$${JAR}" "$(DESTDIR)$(PKG_JAVA_DIR)/$${artifact_id}.jar"; \
	done

install_files:
	install -d $(DESTDIR)$(PKG_SYSCONF_DIR)/engine.conf.d
	install -d $(DESTDIR)$(PKG_SYSCONF_DIR)/ovirt-engine-reports
	install -d $(DESTDIR)$(SYSCONF_DIR)/$(OVIRT_REPORTS_NAME)/ovirt-engine-reports.conf.d
	install -d $(DESTDIR)$(BIN_DIR)
	install -d $(DESTDIR)$(SYSCONF_DIR)/httpd/conf.d
	install -d $(DESTDIR)$(DATA_DIR)
	install -d $(DESTDIR)$(DATA_DIR)/reports
	install -d $(DESTDIR)$(DATA_DIR)/server-customizations

	cp -a  reports/repository_files/* $(DESTDIR)$(DATA_DIR)/reports
	install -p -m 660 packaging/10-setup-database-reports.conf $(DESTDIR)$(SYSCONF_DIR)/$(OVIRT_REPORTS_NAME)/ovirt-engine-reports.conf.d
	install -p -m 644 packaging/50-ovirt-engine-reports.conf  $(DESTDIR)$(PKG_SYSCONF_DIR)/engine.conf.d
	install -p -m 644 packaging/z-ovirt-engine-reports-proxy.conf  $(DESTDIR)$(SYSCONF_DIR)/httpd/conf.d
	install -p -m 755 packaging/ssl2jkstrust.py $(DESTDIR)$(DATA_DIR)
	install -p -m 755 packaging/ovirt-engine-reports-setup.py $(DESTDIR)$(DATA_DIR)
	install -p -m 755 packaging/common_utils.py $(DESTDIR)$(DATA_DIR)
	install -p -m 755 packaging/decorators.py $(DESTDIR)$(DATA_DIR)
	install -p -m 644 packaging/default_master.properties $(DESTDIR)$(DATA_DIR)
	install -p -m 644 reports/Reports.xml $(DESTDIR)$(DATA_DIR)
	cp -rpf server-customizations/* $(DESTDIR)$(DATA_DIR)/server-customizations

	ln -s -f $(DATA_DIR)/$(OVIRT_REPORTS_NAME)-setup.py $(DESTDIR)$(BIN_DIR)/$(OVIRT_REPORTS_NAME)-setup
