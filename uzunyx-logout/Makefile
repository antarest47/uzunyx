NAME    := uzunyx-logout
VERSION := 0.1.1
PREFIX  ?= /usr
DESTDIR ?=

PLASMOID_DIR := $(PREFIX)/share/plasma/plasmoids/org.uzunyx.logout

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	(cd package && find . -type f -exec install -Dm644 {} $(DESTDIR)$(PLASMOID_DIR)/{} \;)

uninstall:
	rm -rf $(DESTDIR)$(PLASMOID_DIR)

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
