# Buildtools Bootstrap
#
# Copyright 2020 Scott Court
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# The prefix to place the bootstrap environment in.
PREFIX=/opt/bootstrap

# The prefix to prepare the chroot environment in.
CHROOT=/mnt

# The name of the tar archive to save the bootstrap in.
OUTPUT_FILE=bootstrap.tar

# Whether or not to run the test suites. Set to true to run them, or false to
# skip them.
RUN_TESTS=true

# The maximum number of make jobs to run in parallel.
MAXJOBS=3

# The architecture to target. Note that the host system **must** be able to run
# binaries produced for this architecture.
ARCH=$(shell arch)

# The ID for the distribution in the host triplet.
DISTID=bootstrap

# The minimum version of glibc for the host system
MIN_GLIBC_VERSION=2.11

TARGET=$(ARCH)-$(DISTID)-linux-musl

PACKAGES=\
	.stamp_pkg_binutils_pass1 \
	.stamp_pkg_gcc_pass1 \
	.stamp_pkg_linux_headers \
	.stamp_pkg_musl
ifeq ($(RUN_TESTS), true)
PACKAGES+=.stamp_test_toolchain_pass1
endif
PACKAGES+=\
	.stamp_pkg_binutils_pass2 \
	.stamp_pkg_libstdcxx \
	.stamp_pkg_gcc_pass2 
ifeq ($(RUN_TESTS), true)
PACKAGES+=.stamp_test_toolchain_pass2
endif
PACKAGES+=\
	.stamp_pkg_busybox \
	.stamp_pkg_make \
	.stamp_pkg_perl \
	.stamp_pkg_texinfo \
	.stamp_pkg_pkgtools

DOWNLOADED_PACKAGES=\
	binutils \
	gcc \
	gmp \
	mpfr \
	mpc \
	linux \
	musl \
	busybox \
	make \
	perl \
	texinfo

export PATH:=$(PREFIX)/bin:$(PATH)

export LC_ALL=POSIX

# Do not pass manually set variables to the submakes, and ensure ARCH is not
# passed to the environment (failure to do either of these is known to break
# packages).
MAKEOVERRIDES=
export MAKEOVERRIDES
unexport ARCH

GCC_VERSION=9.2.0

include arch/$(ARCH).mk

$(OUTPUT_FILE): build
	tar cf $@ $(PREFIX)/

# Download all of the sources, verify their integrity, and extract them.
.SECONDARY: src
src: download verify extract

# Make the necessary perparations for the build environment
.SECONDARY: prepare
prepare: .stamp_prepare

# Build the bootstrap environment
.SECONDARY: build
build: .stamp_prepare $(PACKAGES) 

.PHONY: clean
clean:
	rm -rf build download src .stamp_* $(OUTPUT_FILE)
	rm -rf $(PREFIX)/*

.PHONY: tidy
tidy:
	rm -rf build download src

.PHONY: scrub
scrub: clean-chroot
	rm -rf build
	rm -rf .stamp_pkg_*
	rm -rf .stamp_test_*
	rm -rf .stamp_prepare
	rm -rf $(PREFIX)/*

.SECONDARY: download
download: .stamp_download

.stamp_download: meta/wget_urls
	rm -rf download
	mkdir -p download
	cd download; wget $$(cat ../meta/wget_urls)
	touch $@

.SECONDARY: verify
verify: .stamp_verify

.stamp_verify: .stamp_download meta/wget_shasums
	cd download; shasum -c ../meta/wget_shasums
	touch $@

.SECONDARY: extract
extract: .stamp_extract

.stamp_extract: .stamp_download .stamp_verify .stamp_extract_prepare
	make $(addprefix extract-pkg-,$(DOWNLOADED_PACKAGES))
	touch $@

.stamp_extract_prepare:
	mkdir -p src
	touch $@

.PHONY: extract-pkg-%
extract-pkg-%:
	tar x -C src -f download/$*-*.tar*

.stamp_prepare: .stamp_extract
	mkdir -p $(PREFIX)
	rm -rf $(PREFIX)/*
	cd $(PREFIX); ln -s lib lib$(ARCH_BITS)
	cd $(PREFIX); mkdir -p opt
	cd $(PREFIX)/opt; ln -s ../ bootstrap
	mkdir -p build
	touch $@

.stamp_pkg_binutils_pass1: .stamp_prepare
	# Binutils documentation recommends building in a dedicated build
	# directory.
	rm -rf build/binutils_pass1
	mkdir -p build/binutils_pass1
	cd build/binutils_pass1; \
		../../src/binutils-*/configure \
			--prefix=$(PREFIX) \
			--with-sysroot=$(PREFIX) \
			--with-lib-path=$(PREFIX)/lib \
			--target=$(TARGET) \
			--disable-nls \
			--disable-werror
	cd build/binutils_pass1; make -j $(MAXJOBS)
	cd build/binutils_pass1; make install
	touch $@

.stamp_pkg_gcc_pass1: .stamp_pkg_binutils_pass1
	# GCC documenation recommends building in a dedicated build directory.
	rm -rf build/gcc_pass1
	mkdir -p build/gcc_pass1
	cp -r src/gcc-*/* build/gcc_pass1/
	# GCC requires mpfr, gmp and mpc.
	cp -r src/mpfr-* build/gcc_pass1/mpfr
	cp -r src/gmp-* build/gcc_pass1/gmp
	cp -r src/mpc-* build/gcc_pass1/mpc
	# Remove the hardcoded instances of /usr:
	cd build/gcc_pass1; \
	for file in \
		gcc/config/linux.h \
		$(ARCH_GCC_HEADERS); \
	do \
		cp -uv $$file $$file.orig; \
		sed -e 's@/lib\(64\)\?\(32\)\?/ld@/$(PREFIX)&@g' \
		    -e 's@/usr@$(PREFIX)@g' $$file.orig > $$file; \
		echo -e '\n#undef STANDARD_STARTFILE_PREFIX_1\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_1 "$(PREFIX)/lib/"\n#define STANDARD_STARTFILE_PREFIX_2 ""' >> $$file; \
		touch $$file.orig; \
	done
	cd build/gcc_pass1/mpfr && autoreconf -f 
	mkdir -p build/gcc_pass1/build
	cd build/gcc_pass1/build; \
		../configure \
			--target=$(TARGET) \
			--prefix=$(PREFIX) \
			--with-glibc-version-$(MIN_GLIBC_VERSION) \
			--with-sysroot=$(PREFIX) \
			--with-newlib \
			--without-headers \
			--with-local-prefix=$(PREFIX) \
			--with-native-system-header-dir=$(PREFIX)/include \
			--disable-nls \
			--disable-shared \
			--disable-multilib \
			--disable-decimal-float \
			--disable-threads \
			--disable-libatomic \
			--disable-libgomp \
			--disable-libquadmath \
			--disable-libssp \
			--disable-libvtv \
			--disable-libstdcxx \
			--enable-languages=c,c++
	cd build/gcc_pass1/build; make -j $(MAXJOBS)
	cd build/gcc_pass1/build; make install
	touch $@

.stamp_pkg_linux_headers: .stamp_pkg_gcc_pass1
	rm -rf build/linux
	mkdir -p build/linux
	cp -r src/linux-*/* build/linux/
	cd build/linux && make mrproper
	cd build/linux && make headers
	cp -rv build/linux/usr/include/* $(PREFIX)/include
	touch $@

.stamp_pkg_musl: .stamp_pkg_linux_headers
	rm -rf build/musl
	mkdir -p build/musl
	cp -r src/musl-*/* build/musl/
	cd build/musl; ./configure \
		--prefix=$(PREFIX) \
		--host=$(TARGET) \
		--syslibdir=$(PREFIX)/lib \
		--with-headers=$(PREFIX)/include
	cd build/musl; make -j $(MAXJOBS)
	cd build/musl; make install
	touch $@

.stamp_test_toolchain_pass1: .stamp_pkg_musl
	rm -rf build/test_toolchain_pass1
	mkdir -p build/test_toolchain_pass1
	$(info Test 1: Sanity check the C compiler)
	echo 'int main(){}' > build/test_toolchain_pass1/test1.c
	$(PREFIX)/bin/$(TARGET)-gcc build/test_toolchain_pass1/test1.c \
		-o build/test_toolchain_pass1/test1
	$(PREFIX)/bin/$(TARGET)-readelf -l build/test_toolchain_pass1/test1 \
		| grep '$(PREFIX)/lib/ld-musl-$(ARCH_LD_ARCH)'
	$(info Test 2: Sanity check the C++ compiler)
	echo 'int main(){}' > build/test_toolchain_pass1/test2.cpp
	$(PREFIX)/bin/$(TARGET)-gcc build/test_toolchain_pass1/test2.cpp \
		-o build/test_toolchain_pass1/test2
	$(PREFIX)/bin/$(TARGET)-readelf -l build/test_toolchain_pass1/test2 \
		| grep '$(PREFIX)/lib/ld-musl-$(ARCH_LD_ARCH)'
	touch $@

.stamp_pkg_binutils_pass2: export CC=$(TARGET)-gcc
.stamp_pkg_binutils_pass2: export AR=$(TARGET)-ar 
.stamp_pkg_binutils_pass2: export RANLIB=$(TARGET)-ranlib
.stamp_pkg_binutils_pass2: .stamp_pkg_musl
	# Binutils documentation recommends building in a dedicated build
	# directory.
	rm -rf build/binutils_pass2
	mkdir -p build/binutils_pass2
	cd build/binutils_pass2; \
		../../src/binutils-*/configure \
			--prefix=$(PREFIX) \
			--host=$(TARGET) \
			--with-sysroot \
			--with-lib-path=$(PREFIX)/lib \
			--disable-nls \
			--disable-werror
	cd build/binutils_pass2; make -j $(MAXJOBS)
	cd build/binutils_pass2; make install
# Build an adjusted linker for use later
	cd build/binutils_pass2 && make -C ld clean
	cd build/binutils_pass2 && make -C ld LIB_PATH=/usr/lib:/lib
	cd build/binutils_pass2 && cp -v ld/ld-new $(PREFIX)/bin/
	touch $@

.stamp_pkg_libstdcxx: export CC=$(TARGET)-gcc
.stamp_pkg_libstdcxx: export CXX=$(TARGET)-g++
.stamp_pkg_libstdcxx: export AR=$(TARGET)-ar
.stamp_pkg_libstdcxx: export RANLIB=$(TARGET)-ranlib
.stamp_pkg_libstdcxx: .stamp_pkg_binutils_pass2
	rm -rf build/libstdcxx
	mkdir -p build/libstdcxx/build
	cp -r src/gcc-*/* build/libstdcxx/
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0010_all_default-relro.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0016-invalid_tls_model.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0020_all_default-fortify-source.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0030_all_default-as-needed.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0040_gcc-as-needed-gold.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0050_all_default-warn-format-security.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0060_all_default-warn-trampolines.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0070_all_default-ssp-fix.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0080_all_msgfmt-libstdc++-link.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0090_all_libiberty-asprintf.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0100_all_libiberty-pic.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0110_all_libitm-no-fortify-source.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0120_all_pr55930-dependency-tracking.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0130_gcc-poison-system-directories.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0140_libgcc_s.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0150_nopie.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0160_posix_memalign.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0170_s390x-muslldso.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0180_ldbl128-config.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/0190_static-pie.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/320-libffi-gnulinux.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/400-dlang-phobos.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/401-dlang-32bits.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/402-dlang-stat.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/403-dlang-ibmz.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/404-dlang-zlib.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/405-dlang-mips.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/ada-musl.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/ada-shared.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/fix-cxxflags-passing.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/gcc-4.9-musl-fortify.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/gcc-pure64-mips.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/gcc-pure64.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/libgcc-always-build-gcceh.a.patch
	cd build/libstdcxx && patch -p1 < ../../patches/gcc/libgnarl-musl.patch
	cd build/libstdcxx/build; ../libstdc++-v3/configure \
		--prefix=$(PREFIX) \
		--host=$(TARGET) \
		--disable-multilib \
		--disable-nls \
		--disable-libstdcxx-threads \
		--disable-libstdcxx-pch \
		--with-gxx-include-dir=$(PREFIX)/$(TARGET)/include/c++/$(GCC_VERSION)
	cd build/libstdcxx/build; make -j $(MAXJOBS)
	cd build/libstdcxx/build; make install
	touch $@

.stamp_pkg_gcc_pass2: export CC=$(TARGET)-gcc
.stamp_pkg_gcc_pass2: export CXX=$(TARGET)-g++ 
.stamp_pkg_gcc_pass2: export AR=$(TARGET)-ar 
.stamp_pkg_gcc_pass2: export RANLIB=$(TARGET)-ranlib
.stamp_pkg_gcc_pass2: .stamp_pkg_libstdcxx
	# GCC documenation recommends building in a dedicated build directory.
	rm -rf build/gcc_pass2
	mkdir -p build/gcc_pass2
	cp -r src/gcc-*/* build/gcc_pass2/
	# Apply some needed patches
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0010_all_default-relro.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0016-invalid_tls_model.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0020_all_default-fortify-source.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0030_all_default-as-needed.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0040_gcc-as-needed-gold.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0050_all_default-warn-format-security.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0060_all_default-warn-trampolines.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0070_all_default-ssp-fix.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0080_all_msgfmt-libstdc++-link.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0090_all_libiberty-asprintf.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0100_all_libiberty-pic.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0110_all_libitm-no-fortify-source.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0120_all_pr55930-dependency-tracking.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0130_gcc-poison-system-directories.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0140_libgcc_s.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0150_nopie.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0160_posix_memalign.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0170_s390x-muslldso.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0180_ldbl128-config.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/0190_static-pie.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/320-libffi-gnulinux.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/400-dlang-phobos.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/401-dlang-32bits.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/402-dlang-stat.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/403-dlang-ibmz.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/404-dlang-zlib.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/405-dlang-mips.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/ada-musl.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/ada-shared.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/fix-cxxflags-passing.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/gcc-4.9-musl-fortify.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/gcc-pure64-mips.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/gcc-pure64.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/libgcc-always-build-gcceh.a.patch
	cd build/gcc_pass2 && patch -p1 < ../../patches/gcc/libgnarl-musl.patch
	
	# Replace the temporary limits.h header with the permanent one.
	cd build/gcc_pass2; cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
		$(PREFIX)/lib/gcc/$(TARGET)/$(GCC_VERSION)/include-fixed/limits.h
	# GCC requires mpfr, gmp and mpc.
	cp -r src/mpfr-* build/gcc_pass2/mpfr
	cp -r src/gmp-* build/gcc_pass2/gmp
	cp -r src/mpc-* build/gcc_pass2/mpc
	cd build/gcc_pass2/mpfr && autoreconf -f 
	cd build/gcc_pass2; \
	for file in \
		gcc/config/linux.h \
		$(ARCH_GCC_HEADERS); \
	do \
		cp -uv $$file $$file.orig; \
		sed -e 's@/lib\(64\)\?\(32\)\?/ld@/$(PREFIX)&@g' \
		    -e 's@/usr@$(PREFIX)@g' $$file.orig > $$file; \
		echo -e '\n#undef STANDARD_STARTFILE_PREFIX_1\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_1 "$(PREFIX)/lib/"\n#define STANDARD_STARTFILE_PREFIX_2 ""' >> $$file; \
		touch $$file.orig; \
	done
	mkdir -p build/gcc_pass2/build
	cd build/gcc_pass2/build; \
		../configure \
			--prefix=$(PREFIX) \
			--host=$(TARGET) \
			--with-local-prefix=$(PREFIX) \
			--with-native-system-header-dir=$(PREFIX)/include \
			--disable-multilib \
			--disable-shared \
			--disable-bootstrap \
			--disable-nls \
			--disable-libgomp \
			--disable-libssp \
			--disable-libstdcxx \
			--disable-libstdcxx-pch \
			--enable-languages=c,c++
	cd build/gcc_pass2/build; make -j $(MAXJOBS)
	cd build/gcc_pass2/build; make install
	cd $(PREFIX)/bin; ln -sv gcc cc
	touch $@

.stamp_test_toolchain_pass2: .stamp_pkg_gcc_pass2
	rm -rf build/test_toolchain_pass2
	mkdir -p build/test_toolchain_pass2
	$(info Test 1: Sanity check the C compiler)
	echo 'int main(){}' > build/test_toolchain_pass2/test1.c
	$(PREFIX)/bin/$(TARGET)-gcc build/test_toolchain_pass2/test1.c \
		-o build/test_toolchain_pass2/test1
	$(PREFIX)/bin/$(TARGET)-readelf -l build/test_toolchain_pass2/test1 \
		| grep '$(PREFIX)/lib/ld-musl-$(ARCH_LD_ARCH)'
	$(info Test 2: Sanity check the C++ compiler)
	echo 'int main(){}' > build/test_toolchain_pass2/test2.cpp
	$(PREFIX)/bin/$(TARGET)-gcc build/test_toolchain_pass2/test2.cpp \
		-o build/test_toolchain_pass2/test2
	$(PREFIX)/bin/$(TARGET)-readelf -l build/test_toolchain_pass2/test2 \
		| grep '$(PREFIX)/lib/ld-musl-$(ARCH_LD_ARCH)'
	touch $@

.stamp_pkg_busybox: .stamp_pkg_gcc_pass2
	rm -rf build/busybox
	mkdir -p build/busybox
	cp -r src/busybox-*/* build/busybox/
	cp meta/busybox-config build/busybox/.config
	cd build/busybox && \
		patch -p1 < ../../patches/busybox/date-use-64.patch
	cd build/busybox && \
		patch -p1 < ../../patches/busybox/time-use-64.patch
	cd build/busybox && \
		patch -p1 < ../../patches/busybox/runsv-use-64.patch
	cd build/busybox && \
		patch -p1 < ../../patches/busybox/remove-syscall-wrappers.patch
	cd build/busybox && make -j$(MAXJOBS) CROSS_COMPILE=$(PREFIX)/bin/
	cd build/busybox && make CONFIG_PREFIX=$(PREFIX) install
	touch $@

.stamp_pkg_make: .stamp_pkg_busybox
	rm -rf build/make
	mkdir -p build/make
	cp -r src/make-*/* build/make/
	cd build/make; ./configure \
		--prefix=$(PREFIX) \
		--without-guile
	cd build/make; make -j $(MAXJOBS)
	cd build/make; make install
	touch $@

.stamp_pkg_perl: .stamp_pkg_make
	rm -rf build/perl
	cp -r src/perl-*/ build/perl
ifeq ($(ARCH), i686)
	cd build/perl && \
		patch -p1 < ../../patches/perl/disable-stack-protector.patch
endif
	cd build/perl; sh Configure \
		-des \
		-Dprefix=$(PREFIX) \
		-Dlibs=-lm \
		-Dcc=$(PREFIX)/bin/cc \
		-Uloclibpth \
		-Ulocincpth \
		-Accflags="-fno-stack-protector"
	cd build/perl; make -j $(MAXJOBS)
	cd build/perl; make install
	touch $@

.stamp_pkg_texinfo: .stamp_pkg_perl
	rm -rf build/texinfo
	mkdir -p build/texinfo
	cp -r src/texinfo-*/* build/texinfo/
	cd build/texinfo; ./configure \
		--prefix=$(PREFIX)
	cd build/texinfo; make -j $(MAXJOBS)
	cd build/texinfo; make install
	touch $@

.stamp_pkg_pkgtools: .stamp_pkg_texinfo
	make -C pkgtools install DESTDIR=$(PREFIX)
	touch $@

.SECONDARY: prepare-chroot
prepare-chroot: .stamp_chroot_prepare .stamp_chroot_ossrc

.stamp_chroot_prepare: $(OUTPUT_FILE)
	mkdir -p "$(CHROOT)"
	tar xf $(OUTPUT_FILE) -C "$(CHROOT)"
	mkdir -p "$(CHROOT)/bin"
	ln -s $(PREFIX)/bin/sh "$(CHROOT)/bin/"
	mkdir -p "$(CHROOT)/etc"
	install -m 644 /etc/resolv.conf "$(CHROOT)/etc/"
	mkdir -p "$(CHROOT)/dev"
	mkdir -p "$(CHROOT)/proc"
	mkdir -p "$(CHROOT)/sys"
	touch $@

.stamp_chroot_ossrc: .stamp_chroot_prepare
	mkdir -p "$(CHROOT)/usr/src"
	cp -r ossrc/* "$(CHROOT)/usr/src/"
	cp -r ossrc/.g* "$(CHROOT)/usr/src/"
	touch $@

.PHONY: clean-chroot
clean-chroot:
	rm -f .stamp_chroot*

.PHONY: chroot
chroot: prepare-chroot
	chown -v 0:0 \
		"$(CHROOT)/bin" \
		"$(CHROOT)/dev" \
		"$(CHROOT)/etc" \
		"$(CHROOT)/etc/resolv.conf" \
		"$(CHROOT)/proc" \
		"$(CHROOT)/sys" \
		"$(CHROOT)/usr/src" 
	chroot "$(CHROOT)" /bin/sh -c \
		'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$(PREFIX)/sbin:$(PREFIX)/bin; \
		[ -e /proc/self ] || mount -t proc proc /proc; \
		[ -d /sys/kernel ] || mount -t sysfs sys /sys; \
		mdev -s; mdev -d; chmod 666 /dev/null; \
		/bin/sh'

