PKG_NAME=busybox
PKG_VERSION=1.31.1
PKG_BUILD=3
PKG_BUILDSYSTEM=custom-common

# Build time dependencies for this package
PKG_BUILD_DEPENDS=musl libcap

PKG_WGET_URLS=https://busybox.net/downloads/busybox-$(PKG_VERSION).tar.bz2
PKG_SRC_ARCHIVES=busybox-$(PKG_VERSION).tar.bz2
PKG_SRC_DIR=busybox-$(PKG_VERSION)

include toolchain.mk

ifeq ($(CROSS_COMPILE), y)
MAKE_ARGS+=		CROSS_COMPILE="$(CROSS_TARGET_TRIPLET)-"
MAKE_INSTALL_ARGS+=	CROSS_COMPILE="$(CROSS_TARGET_TRIPLET)-"
endif

include package.mk

# Put custom build rules here. This target runs with $PWD set to the directory
# of this Makefile. Do NOT delete the touch $@.
.stamp_custom_build: 
ifeq ($(PKG_OS_TAG), bs)
	cp busybox-bootstrap-config pkg_src/$(PKG_SRC_DIR)/.config
else
	cp busybox-config pkg_src/$(PKG_SRC_DIR)/.config
endif
	make -C pkg_src/$(PKG_SRC_DIR) $(MAKE_FLAGS) $(MAKE_ARGS)
	make -C pkg_src/$(PKG_SRC_DIR) install CONFIG_PREFIX=$(PKG_ROOT) \
		$(MAKE_INSTALL_ARGS)
	install -dm 755 $(PKG_ROOT)/var/spool/cron
	install -dm 1730 $(PKG_ROOT)/var/spool/cron/crontabs

	ln -sf mdev $(PKG_ROOT)/sbin/hotplug
	chmod 755 $(PKG_ROOT)/lib*/libbusybox.so.*
	install -dm 755 $(PKG_ROOT)/etc/init.d
	install -m 644 ashrc $(PKG_ROOT)/etc/
	install -m 755 init.d/network $(PKG_ROOT)/etc/init.d/
	install -m 755 init.d/syslogd $(PKG_ROOT)/etc/init.d/
	install -m 755 init.d/klogd $(PKG_ROOT)/etc/init.d/
	install -m 755 init.d/crond $(PKG_ROOT)/etc/init.d/

# Install networking config files
	install -d $(PKG_ROOT)/usr/share/udhcpc
	install -m 755 udhcpc.script $(PKG_ROOT)/usr/share/udhcpc/default.script
	install -dm 755 $(PKG_ROOT)/etc/network/if-down.d
	install -dm 755 $(PKG_ROOT)/etc/network/if-post-down.d
	install -dm 755 $(PKG_ROOT)/etc/network/if-pre-up.d
	install -dm 755 $(PKG_ROOT)/etc/network/if-up.d
	install -m 644 interfaces $(PKG_ROOT)/etc/network/
	pkgtool preserve-file $(PKG_ROOT)/etc/network/interfaces

# Move some binaries that are required early on in the boot process to /bin
	mv $(PKG_ROOT)/usr/bin/find $(PKG_ROOT)/bin/
	mv $(PKG_ROOT)/usr/bin/xargs $(PKG_ROOT)/bin/
	mv $(PKG_ROOT)/usr/bin/sort $(PKG_ROOT)/bin/

# Install the manual pages and documentation
	install -dm 755 $(PKG_ROOT)/usr/share/man/man1
	install pkg_src/$(PKG_SRC_DIR)/docs/busybox.1 $(PKG_ROOT)/usr/share/man/man1
	cp man1/*.1 $(PKG_ROOT)/usr/share/man/man1
	install -dm 755 $(PKG_ROOT)/usr/share/man/man5
	cp man5/*.5 $(PKG_ROOT)/usr/share/man/man5
	install -dm 755 $(PKG_ROOT)/usr/share/doc/busybox
	cp $(PKG_SRC)/docs/mdev.txt $(PKG_ROOT)/usr/share/doc/busybox/

# Install the Bash shim
	install -m 755 bash $(PKG_ROOT)/bin/

# Do not delete
	touch $@

