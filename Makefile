PREFIX := i686-w64-mingw32-
PREFIX64 := x86_64-w64-mingw32-

ZLIB_VER := 1.2.12
JPEG_VER := 2.1.3
PNG_VER := 1.6.37
CURL_VER := 7.83.1
OPENAL_VER := 1.22.0
OPENGL_VER := 3f46e23b3875c0ab5674d8d6807d993c00ed6317
EGL_VER := 84f25dd4c04a01ea48480f7296ba9d64d435fa87

ZLIB := zlib-$(ZLIB_VER)
JPEG := libjpeg-turbo-$(JPEG_VER)
PNG := libpng-$(PNG_VER)
CURL := curl-$(CURL_VER)
OPENAL := openal-soft-$(OPENAL_VER)

DL_DIR := cache
DL_CMD := wget -P $(DL_DIR)

ZLIB_TAR := $(ZLIB).tar.xz
JPEG_TAR := $(JPEG).tar.gz
PNG_TAR := $(PNG).tar.xz
CURL_TAR := $(CURL).tar.xz
OPENAL_TAR := $(OPENAL).tar.bz2

ALL_TAR := $(ZLIB_TAR) $(JPEG_TAR) $(PNG_TAR) $(CURL_TAR) $(OPENAL_TAR) glext.h wglext.h khrplatform.h
ALL_TAR := $(patsubst %,$(DL_DIR)/%,$(ALL_TAR))

CURL_CFLAG_EXTRAS := -DCURL_STATICLIB -DHTTP_ONLY -DCURL_DISABLE_CRYPTO_AUTH
CURL_CFG := -zlib -ipv6 -schannel

DESTDIR ?= .
INC := $(DESTDIR)/inc
LIB := $(DESTDIR)/lib
LIB64 := $(DESTDIR)/lib64

all: zlib jpeg png curl zlib64 jpeg64 png64 curl64

default: all

.PHONY: clean distclean install

$(DL_DIR)/$(ZLIB_TAR):
	$(DL_CMD) https://www.zlib.net/$(ZLIB_TAR)

$(DL_DIR)/$(JPEG_TAR):
	$(DL_CMD) https://downloads.sourceforge.net/sourceforge/libjpeg-turbo/$(JPEG_TAR)

$(DL_DIR)/$(PNG_TAR):
	$(DL_CMD) https://downloads.sourceforge.net/sourceforge/libpng/$(PNG_TAR)

$(DL_DIR)/$(CURL_TAR):
	$(DL_CMD) https://curl.haxx.se/download/$(CURL_TAR)

$(DL_DIR)/$(OPENAL_TAR):
	$(DL_CMD) https://openal-soft.org/openal-releases/$(OPENAL_TAR)

$(DL_DIR)/glext.h:
	$(DL_CMD) https://raw.githubusercontent.com/KhronosGroup/OpenGL-Registry/$(OPENGL_VER)/api/GL/glext.h

$(DL_DIR)/wglext.h:
	$(DL_CMD) https://raw.githubusercontent.com/KhronosGroup/OpenGL-Registry/$(OPENGL_VER)/api/GL/wglext.h

$(DL_DIR)/khrplatform.h:
	$(DL_CMD) https://raw.githubusercontent.com/KhronosGroup/EGL-Registry/$(EGL_VER)/api/KHR/khrplatform.h

fetch: fetch-stamp
fetch-stamp: $(ALL_TAR)
	sha256sum -c checksum
	touch $@

genchecksum: $(ALL_TAR)
	sha256sum $(ALL_TAR) > checksum

extract: extract-stamp
extract-stamp: fetch-stamp
	mkdir -p build build64
	tar -C build -xf $(DL_DIR)/$(ZLIB_TAR)
	tar -C build -xf $(DL_DIR)/$(JPEG_TAR)
	tar -C build -xf $(DL_DIR)/$(PNG_TAR)
	tar -C build -xf $(DL_DIR)/$(CURL_TAR)
	tar -C build -xf $(DL_DIR)/$(OPENAL_TAR) $(OPENAL)/include/AL
	tar -C build64 -xf $(DL_DIR)/$(ZLIB_TAR)
	tar -C build64 -xf $(DL_DIR)/$(PNG_TAR)
	tar -C build64 -xf $(DL_DIR)/$(CURL_TAR)
	touch $@

zlib: zlib-stamp
zlib-stamp: extract-stamp
	$(MAKE) -C build/$(ZLIB) -f win32/Makefile.gcc \
		PREFIX=$(PREFIX) \
		libz.a
	touch $@

jpeg: jpeg-stamp
jpeg-stamp: extract-stamp
	cmake -G"Unix Makefiles" \
		-DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/cmake/toolchain.cmake \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/build/jpeg-install \
		-DENABLE_SHARED=0 -S build/$(JPEG) -B build/jpeg-build
	$(MAKE) -C build/jpeg-build jpeg-static
	touch $@

png: png-stamp
png-stamp: zlib-stamp
	$(MAKE) -C build/$(PNG) -f scripts/makefile.gcc \
		CC="$(PREFIX)gcc" \
		AR_RC="$(PREFIX)ar rcs" \
		RANLIB="$(PREFIX)ranlib" \
		RC="$(PREFIX)windres" \
		STRIP="$(PREFIX)strip" \
		ZLIBINC=../$(ZLIB) \
		ZLIBLIB=../$(ZLIB) \
		libpng.a
	touch $@

curl: curl-stamp
curl-stamp: zlib-stamp
	ZLIB_PATH=../../$(ZLIB) \
	$(MAKE) -C build/$(CURL)/lib -f Makefile.m32 \
		CROSSPREFIX="$(PREFIX)" \
		CURL_CFLAG_EXTRAS="$(CURL_CFLAG_EXTRAS)" \
		CFG="$(CURL_CFG)" \
		libcurl.a
	touch $@

zlib64: zlib64-stamp
zlib64-stamp: extract-stamp
	$(MAKE) -C build64/$(ZLIB) -f win32/Makefile.gcc \
		PREFIX=$(PREFIX64) \
		libz.a
	touch $@

jpeg64: jpeg64-stamp
jpeg64-stamp: extract-stamp
	cmake -G"Unix Makefiles" \
		-DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/cmake/toolchain64.cmake \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/build64/jpeg-install \
		-DENABLE_SHARED=0 -S build/$(JPEG) -B build64/jpeg-build
	$(MAKE) -C build64/jpeg-build jpeg-static
	touch $@

png64: png64-stamp
png64-stamp: zlib64-stamp
	$(MAKE) -C build64/$(PNG) -f scripts/makefile.gcc \
		CC="$(PREFIX64)gcc" \
		AR_RC="$(PREFIX64)ar rcs" \
		RANLIB="$(PREFIX64)ranlib" \
		RC="$(PREFIX64)windres" \
		STRIP="$(PREFIX64)strip" \
		ZLIBINC=../$(ZLIB) \
		ZLIBLIB=../$(ZLIB) \
		libpng.a
	touch $@

curl64: curl64-stamp
curl64-stamp: zlib64-stamp
	ZLIB_PATH=../../$(ZLIB) ARCH=w64 \
	$(MAKE) -C build64/$(CURL)/lib -f Makefile.m32 \
		CROSSPREFIX="$(PREFIX64)" \
		CURL_CFLAG_EXTRAS="$(CURL_CFLAG_EXTRAS)" \
		CFG="$(CURL_CFG)" \
		libcurl.a
	touch $@

clean:
	rm -rf build build64
	rm -f *-stamp

distclean: clean
	rm -rf cache

install: all
	install -d $(INC) $(LIB) $(LIB64) $(INC)/curl $(INC)/AL $(INC)/GL $(INC)/KHR
	install -m 644 build/$(ZLIB)/zconf.h $(INC)/zconf.h
	install -m 644 build/$(ZLIB)/zlib.h $(INC)/zlib.h
	install -m 644 build/$(ZLIB)/libz.a $(LIB)/libz.a
	install -m 644 build/$(JPEG)/jpeglib.h $(INC)/jpeglib.h
	install -m 644 build/$(JPEG)/jmorecfg.h $(INC)/jmorecfg.h
	install -m 644 build/jpeg-build/jconfig.h $(INC)/jconfig.h
	install -m 644 build/jpeg-build/libjpeg.a $(LIB)/libjpeg.a
	install -m 644 build/$(PNG)/pngconf.h $(INC)/pngconf.h
	install -m 644 build/$(PNG)/png.h $(INC)/png.h
	install -m 644 build/$(PNG)/pnglibconf.h $(INC)/pnglibconf.h
	install -m 644 build/$(PNG)/libpng.a $(LIB)/libpng.a
	install -m 644 build/$(CURL)/include/curl/*.h $(INC)/curl
	install -m 644 build/$(CURL)/lib/libcurl.a $(LIB)/libcurl.a
	install -m 644 build64/$(ZLIB)/libz.a $(LIB64)/libz.a
	install -m 644 build64/jpeg-build/libjpeg.a $(LIB64)/libjpeg.a
	install -m 644 build64/$(PNG)/libpng.a $(LIB64)/libpng.a
	install -m 644 build64/$(CURL)/lib/libcurl.a $(LIB64)/libcurl.a
	install -m 644 $(DL_DIR)/glext.h $(DL_DIR)/wglext.h $(INC)/GL
	install -m 644 $(DL_DIR)/khrplatform.h $(INC)/KHR
	install -m 644 build/$(OPENAL)/include/AL/* $(INC)/AL
