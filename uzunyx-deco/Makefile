NAME    := uzunyx-deco
VERSION := 0.13.2
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

DECO_DIR := $(PREFIX)/share/kwin/decorations/uzunyx
FILES    := metadata.json contents/ui/main.qml contents/ui/UzunyxButton.qml
# Window button images, shared with uzunyx-buttons (make svg there)
BUTTONS_SVG := $(wildcard ../uzunyx-buttons/svg/*.svg)
SCRIPTS_DIR  := $(PREFIX)/share/kwin-wayland/scripts
SCRIPTS      := softmaximize panelconfigretry macfullscreen
SCRIPT_FILES := metadata.json contents/code/main.js
TABBOX_DIR   := $(PREFIX)/share/kwin-wayland/tabbox

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	for f in $(FILES); do install -Dm644 package/$$f $(DESTDIR)$(DECO_DIR)/$$f; done
	install -d $(DESTDIR)$(DECO_DIR)/contents/buttons
	install -m644 $(BUTTONS_SVG) $(DESTDIR)$(DECO_DIR)/contents/buttons/
	for s in $(SCRIPTS); do for f in $(SCRIPT_FILES); do install -Dm644 kwin/$$s/$$f $(DESTDIR)$(SCRIPTS_DIR)/$$s/$$f; done; done
	for f in metadata.json contents/ui/main.qml; do install -Dm644 kwin/tabbox/uzunyx_cover/$$f $(DESTDIR)$(TABBOX_DIR)/uzunyx_cover/$$f; done
	install -Dm644 kwinrc $(DESTDIR)$(SYSCONFDIR)/xdg/kwinrc

uninstall:
	rm -rf $(DESTDIR)$(DECO_DIR)
	for s in $(SCRIPTS); do rm -rf $(DESTDIR)$(SCRIPTS_DIR)/$$s; done
	rm -rf $(DESTDIR)$(TABBOX_DIR)/uzunyx_cover
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/kwinrc

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
