NAME    := uzunyx-shortcuts
VERSION := 0.8.0
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	install -Dm755 uzunyx-shortcuts-setup $(DESTDIR)$(PREFIX)/bin/uzunyx-shortcuts-setup
	install -Dm644 uzunyx-shortcuts-setup.desktop $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/uzunyx-shortcuts-setup.desktop

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/uzunyx-shortcuts-setup
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/uzunyx-shortcuts-setup.desktop

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
