NAME    := uzunyx-tiling
VERSION := 0.9.1
PREFIX  ?= /usr
DESTDIR ?=

SCRIPT       := uzunyxtiling
PLASMOID     := org.uzunyx.tiling
SCRIPT_DIR   := $(PREFIX)/share/kwin-wayland/scripts/$(SCRIPT)
PLASMOID_DIR := $(PREFIX)/share/plasma/plasmoids/$(PLASMOID)
MO           := $(PREFIX)/share/locale/es/LC_MESSAGES/plasma_applet_$(PLASMOID).mo

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install deb clean

all:
	@echo "Targets: install, deb, clean"

install:
	install -Dm755 uzunyx-tiling $(DESTDIR)$(PREFIX)/bin/uzunyx-tiling
	install -Dm755 uzunyx-tiling-handles $(DESTDIR)$(PREFIX)/libexec/uzunyx-tiling-handles
	install -Dm644 dbus/org.uzunyx.TilingHandles.service $(DESTDIR)$(PREFIX)/share/dbus-1/services/org.uzunyx.TilingHandles.service
	install -Dm644 org.uzunyx.tiling-cycle.desktop $(DESTDIR)$(PREFIX)/share/applications/org.uzunyx.tiling-cycle.desktop
	(cd kwin/$(SCRIPT) && find . -type f -exec install -Dm644 {} $(DESTDIR)$(SCRIPT_DIR)/{} \;)
	for s in uzunyxdesktops uzunyxgestures; do \
		(cd kwin/$$s && find . -type f -exec install -Dm644 {} $(DESTDIR)$(dir $(SCRIPT_DIR))$$s/{} \;); \
	done
	(cd kwin/effects/uzunyxtilemotion && find . -type f -exec install -Dm644 {} $(DESTDIR)$(PREFIX)/share/kwin-wayland/effects/uzunyxtilemotion/{} \;)
	(cd package && find . -type f -exec install -Dm644 {} $(DESTDIR)$(PLASMOID_DIR)/{} \;)
	install -d $(dir $(DESTDIR)$(MO))
	msgfmt po/es.po -o $(DESTDIR)$(MO)
	chmod 644 $(DESTDIR)$(MO)

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 README.md $(BUILD)/root/usr/share/doc/$(NAME)/README.md
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
