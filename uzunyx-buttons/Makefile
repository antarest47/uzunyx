NAME    := uzunyx-buttons
VERSION := 0.8.2
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

BUILD := build

GTK_DIR  := $(PREFIX)/share/themes/Breeze-Uzunyx
ICON_DIR := $(PREFIX)/share/icons/uzunyx
# Folder and Dolphin icons (SVG), kept in the repo's icons/ directory: only
# their emblems are used, on each edition's folder (gen-folders.py). The
# uzunyx theme has Akane's; uzunyx-sora, which inherits from it, Sora's.
FOLDERS  := ../icons/iconos-carpetas-v2
EDITION_FOLDERS := $(BUILD)/folders
BUTTONS  := minimize maximize close
STATES   := normal hover active backdrop

DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all svg install uninstall deb clean

all:
	@echo "Targets: svg, install, uninstall, deb, clean"

# Regenerates svg/ (committed; uzunyx-deco also uses it)
svg:
	python3 gen-buttons.py svg

install:
	install -d $(DESTDIR)$(GTK_DIR)/buttons $(DESTDIR)$(GTK_DIR)/gtk-3.0 $(DESTDIR)$(GTK_DIR)/gtk-4.0
	install -m644 gtk-index.theme $(DESTDIR)$(GTK_DIR)/index.theme
	for b in $(BUTTONS); do for s in $(STATES); do install -m644 svg/$$b-$$s.svg $(DESTDIR)$(GTK_DIR)/buttons/; done; done
	for v in 3 4; do for f in gtk gtk-dark; do \
		{ printf '@import url("../../Breeze/gtk-%s.0/%s.css");\n\n' $$v $$f; \
		  python3 gen-gtk-css.py $$v ../buttons; } > $(DESTDIR)$(GTK_DIR)/gtk-$$v.0/$$f.css; \
		chmod 644 $(DESTDIR)$(GTK_DIR)/gtk-$$v.0/$$f.css; done; done
	rm -rf $(EDITION_FOLDERS)
	python3 -I gen-folders.py $(FOLDERS) $(EDITION_FOLDERS)
	python3 gen-icons.py svg $(EDITION_FOLDERS)/akane $(DESTDIR)$(ICON_DIR)
	python3 gen-icons.py - $(EDITION_FOLDERS)/sora $(DESTDIR)$(ICON_DIR)-sora uzunyx-sora
	find $(DESTDIR)$(ICON_DIR) $(DESTDIR)$(ICON_DIR)-sora -type d -exec chmod 755 {} + -o -type f -exec chmod 644 {} +
	install -Dm755 uzunyx-gtk-theme-setup $(DESTDIR)$(PREFIX)/bin/uzunyx-gtk-theme-setup
	install -Dm644 uzunyx-gtk-theme-setup.desktop $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/uzunyx-gtk-theme-setup.desktop

uninstall:
	rm -rf $(DESTDIR)$(GTK_DIR) $(DESTDIR)$(ICON_DIR) $(DESTDIR)$(ICON_DIR)-sora
	rm -f $(DESTDIR)$(PREFIX)/bin/uzunyx-gtk-theme-setup
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/uzunyx-gtk-theme-setup.desktop

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
