# KWin effect in C++: it is built against the installed KWin (kwin-dev) and
# only loads in that exact version (KWin checks it in the plugin IID), so the
# package is pinned to it and has to be rebuilt after every KWin update.
NAME    := uzunyx-openclose
VERSION := 0.2.1
DESTDIR ?=

# Upstream version of the KWin we build against, e.g. 6.7.4 (from 4:6.7.4-2+b1)
KWIN_DEB     := $(shell dpkg-query -W -f='$${Version}' kwin-dev 2>/dev/null)
KWIN_VERSION := $(shell echo '$(KWIN_DEB)' | sed 's/^[0-9]*://; s/-[^-]*$$//')
KWIN_EPOCH   := $(shell echo '$(KWIN_DEB)' | sed -n 's/^\([0-9]*\):.*/\1:/p')
DEB_VERSION  := $(VERSION)+kwin$(KWIN_VERSION)
ARCH         := $(shell dpkg --print-architecture)

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(DEB_VERSION)_$(ARCH).deb

.PHONY: all compile install deb clean check-kwin

all:
	@echo "Targets: compile, install, deb, clean (needs kwin-dev, cmake, extra-cmake-modules)"

check-kwin:
	@test -n '$(KWIN_VERSION)' || { echo 'kwin-dev is not installed'; exit 1; }

compile: check-kwin
	cmake -S . -B $(BUILD)/cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF
	cmake --build $(BUILD)/cmake

install: compile
	DESTDIR=$(DESTDIR) cmake --install $(BUILD)/cmake

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	sed -i 's/@VERSION@/$(DEB_VERSION)/; s/@ARCH@/$(ARCH)/; s/@KWIN@/$(KWIN_EPOCH)$(KWIN_VERSION)/g' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
