NAME    := uzunyx-controlcenter
VERSION := 0.9.6
PREFIX  ?= /usr
DESTDIR ?=

PLASMOID     := org.uzunyx.controlcenter
PLASMOID_DIR := $(PREFIX)/share/plasma/plasmoids/$(PLASMOID)
MO           := $(PREFIX)/share/locale/es/LC_MESSAGES/plasma_applet_$(PLASMOID).mo

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	(cd package && find . -type f -exec install -Dm644 {} $(DESTDIR)$(PLASMOID_DIR)/{} \;)
	install -Dm755 uzunyx-controlcenter-helper $(DESTDIR)$(PREFIX)/libexec/uzunyx-controlcenter-helper
	install -d $(dir $(DESTDIR)$(MO))
	msgfmt po/es.po -o $(DESTDIR)$(MO)
	chmod 644 $(DESTDIR)$(MO)

uninstall:
	rm -rf $(DESTDIR)$(PLASMOID_DIR)
	rm -f $(DESTDIR)$(PREFIX)/libexec/uzunyx-controlcenter-helper
	rm -f $(DESTDIR)$(MO)

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 README.md $(BUILD)/root/usr/share/doc/$(NAME)/README.md
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
