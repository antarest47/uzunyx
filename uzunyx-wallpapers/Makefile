# Uzunyx wallpapers as Plasma wallpaper packages, plus the system defaults
# that use them: lock screen and SDDM login theme (Akane's sky, the
# edition by default; uzunyx-edition switches them to Sora's). The desktop default (UzunyxAkane) is set by the uzunyx
# Plasma theme (uzunyx-plasmatheme, plasmarc defaultWallpaperTheme); each
# global theme sets its own (UzunyxAkane, UzunyxSora).
NAME    := uzunyx-wallpapers
VERSION := 0.8.5
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

SRC       := ../wallpapers
SIZE      := 6688x3764
# package id : source image : display name
WALLPAPERS := UzunyxAkane:wallpaper-uzunyx-akane-lll.jpeg:Uzunyx Akane \
              UzunyxSora:wallpaper-uzunyx-sora-lll.jpeg:Uzunyx Sora \
              UzunyxAkaneSky:sddm-uzunyx-akane-lll.jpeg:Uzunyx Akane (sky) \
              UzunyxSoraSky:sddm-uzunyx-sora-lll.jpeg:Uzunyx Sora (sky)
WP_DIR    := $(PREFIX)/share/wallpapers
SDDM_DIR  := $(PREFIX)/share/sddm/themes/uzunyx
# Files of KDE's Breeze SDDM theme reused (symlinked) by the uzunyx one.
BREEZE_SDDM := Background.qml KeyboardButton.qml Login.qml SessionButton.qml default-logo.svg preview.png

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	@set -e; IFS=' '; \
	echo '$(WALLPAPERS)' | sed 's/ \([A-Z][A-Za-z0-9]*:\)/\n\1/g' | while IFS=: read -r id img name; do \
		d=$(DESTDIR)$(WP_DIR)/$$id; \
		install -Dm644 $(SRC)/$$img $$d/contents/images/$(SIZE).jpeg; \
		printf '{\n    "KPlugin": {\n        "Authors": [{"Name": "emi", "Email": "285864120+antarest47@users.noreply.github.com"}],\n        "Id": "%s",\n        "License": "CC0-1.0",\n        "Name": "%s"\n    }\n}\n' "$$id" "$$name" > $$d/metadata.json; \
		chmod 644 $$d/metadata.json; \
		echo "  $$id <- $$img"; \
	done
	install -d $(DESTDIR)$(SDDM_DIR)
	for f in $(BREEZE_SDDM); do ln -sfn ../breeze/$$f $(DESTDIR)$(SDDM_DIR)/$$f; done
	# SDDM prefers the theme's default avatar to the system one: use the system's.
	ln -sfn ../../faces $(DESTDIR)$(SDDM_DIR)/faces
	install -m644 sddm/metadata.desktop sddm/theme.conf sddm/Main.qml sddm/UzunyxActionButton.qml $(DESTDIR)$(SDDM_DIR)/
	# The greeter's user has no settings: the colors of each edition, for it alone.
	for e in akane:Akane sora:Sora; do \
		install -d $(DESTDIR)$(SDDM_DIR)/colors/$${e%:*}; \
		sed '/^\[General\]/,/^$$/d; /^\[KDE\]/,/^$$/d; /^\[WM\]/,/^$$/d' ../uzunyx-colors/color-schemes/Uzunyx$${e#*:}.colors > $(DESTDIR)$(SDDM_DIR)/colors/$${e%:*}/kdeglobals; \
		chmod 644 $(DESTDIR)$(SDDM_DIR)/colors/$${e%:*}/kdeglobals; \
	done
	install -Dm644 sddm/uzunyx.conf $(DESTDIR)$(SYSCONFDIR)/sddm.conf.d/uzunyx.conf
	install -Dm644 sddm/zz-uzunyx-wayland.conf $(DESTDIR)$(SYSCONFDIR)/sddm.conf.d/zz-uzunyx-wayland.conf
	install -Dm644 kscreenlockerrc $(DESTDIR)$(SYSCONFDIR)/xdg/kscreenlockerrc

uninstall:
	rm -rf $(DESTDIR)$(WP_DIR)/UzunyxAkane $(DESTDIR)$(WP_DIR)/UzunyxSora $(DESTDIR)$(WP_DIR)/UzunyxAkaneSky $(DESTDIR)$(WP_DIR)/UzunyxSoraSky
	rm -rf $(DESTDIR)$(SDDM_DIR)
	rm -f $(DESTDIR)$(SYSCONFDIR)/sddm.conf.d/uzunyx.conf $(DESTDIR)$(SYSCONFDIR)/sddm.conf.d/zz-uzunyx-wayland.conf $(DESTDIR)$(SYSCONFDIR)/xdg/kscreenlockerrc

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
