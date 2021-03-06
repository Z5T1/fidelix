OS_SRC_DIR?=$(CURDIR)
export OS_SRC_DIR
DIR:=
SUBDIRS:=\
	base \
	boot \
	util \
	daemon

.PHONY: default
default: install

# Handle bootstrapping targets
.PHONY: bootstrap-%
bootstrap-%:
	$(MAKE) -C bootstrap $@

.PHONY: from-bootstrap
from-bootstrap:
	$(MAKE) -C bootstrap/packages

# Handle /usr/src copying
copy-src:
	cp -au $(OS_SRC_DIR)/* $(SYSROOT)/usr/src/

# Handle /var/packages copying
copy-pkgs:
	mkdir -p $(SYSROOT)/var/packages/$(OS_VERSION)-$(OS_PKG_TAG)/$(OS_ARCH)
	cp -au $(OS_PKG_DIR)/$(OS_VERSION)-$(OS_PKG_TAG)/$(OS_ARCH)/* \
		$(SYSROOT)/var/packages/$(OS_VERSION)-$(OS_PKG_TAG)/$(OS_ARCH)

# Handle package selections
ifdef SELECTION
ifneq ($(wildcard include/selection/$(SELECTION).local.mk), )
include include/selection/$(SELECTION).local.mk
else ifneq ($(wildcard include /selection/$(SELECTION).mk), )
include include/selection/$(SELECTION).mk
endif
endif
.PHONY: install-selection
install-selection: $(addprefix install-,$(SELECTED_PACKAGES))

include sysconfig.mk
include dir.mk
include common-rules.mk

