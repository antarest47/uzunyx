# System Settings module (C++ + QML, built against KF6: no KWin version pin)
# plus the uzunyx-edition command that does the work and its root helper for
# the login screen.
NAME    := uzunyx-editions
VERSION := 0.3.5
PREFIX  ?= /usr
DESTDIR ?=
ARCH    := $(shell dpkg --print-architecture)

DOMAIN := kcm_uzunyx_editions
MO     := $(PREFIX)/share/locale/es/LC_MESSAGES/$(DOMAIN).mo

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_$(ARCH).deb

.PHONY: all compile install deb clean

all:
	@echo "Targets: compile, install, deb, clean"
	@echo "Needs cmake, extra-cmake-modules, qt6-base-dev, qt6-declarative-dev, libkf6kcmutils-dev, libkf6i18n-dev, libkf6config-dev, gettext"

compile:
	cmake -S kcm -B $(BUILD)/cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PREFIX) -DBUILD_TESTING=OFF
	cmake --build $(BUILD)/cmake

install: compile
	DESTDIR=$(DESTDIR) cmake --install $(BUILD)/cmake
	install -Dm755 uzunyx-edition $(DESTDIR)$(PREFIX)/bin/uzunyx-edition
	install -Dm644 org.uzunyx.settings.desktop $(DESTDIR)$(PREFIX)/share/applications/org.uzunyx.settings.desktop
	for e in akane sora; do python3 -I ../uzunyx-lnf/gen-logos.py ../icons/uzunyx-config-$$e.png uzunyx-config-$$e $(DESTDIR)$(PREFIX)/share/icons/hicolor; done
	install -Dm644 uzunyx-edition-sync.desktop $(DESTDIR)/etc/xdg/autostart/uzunyx-edition-sync.desktop
	install -Dm755 uzunyx-system-edition $(DESTDIR)$(PREFIX)/libexec/uzunyx-system-edition
	install -Dm644 org.uzunyx.edition.policy $(DESTDIR)$(PREFIX)/share/polkit-1/actions/org.uzunyx.edition.policy
	install -d $(dir $(DESTDIR)$(MO))
	msgfmt po/es.po -o $(DESTDIR)$(MO)
	chmod 644 $(DESTDIR)$(MO)

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -m755 debian/postrm $(BUILD)/root/DEBIAN/postrm
	install -m644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/; s/@ARCH@/$(ARCH)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
