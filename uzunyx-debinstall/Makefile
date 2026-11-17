NAME    := uzunyx-debinstall
VERSION := 0.1.0
PREFIX  ?= /usr
DESTDIR ?=

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	install -Dm755 uzunyx-debinstall $(DESTDIR)$(PREFIX)/bin/uzunyx-debinstall
	install -Dm644 servicemenus/uzunyx-debinstall.desktop \
		$(DESTDIR)$(PREFIX)/share/kio/servicemenus/uzunyx-debinstall.desktop
	install -Dm644 applications/org.uzunyx.debinstall.desktop \
		$(DESTDIR)$(PREFIX)/share/applications/org.uzunyx.debinstall.desktop

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/uzunyx-debinstall \
		$(DESTDIR)$(PREFIX)/share/kio/servicemenus/uzunyx-debinstall.desktop \
		$(DESTDIR)$(PREFIX)/share/applications/org.uzunyx.debinstall.desktop

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
