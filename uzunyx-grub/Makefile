# GRUB theme for Uzunyx (neutral and dark, the same for both editions) and a
# hidden menu (Esc shows it), through /etc/default/grub.d. The theme is
# installed in /usr/share/uzunyx-grub/theme; the postinst copies it to
# /boot/grub/themes/uzunyx, which GRUB can always read.
NAME    := uzunyx-grub
VERSION := 0.2.2
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

THEME_DIR := $(PREFIX)/share/uzunyx-grub/theme
# Latin (Spanish included), punctuation and arrows.
RANGE     := 0x20-0x7E,0xA0-0x17F,0x2010-0x2027,0x2190-0x21FF
SANS      := /usr/share/fonts/truetype/noto/NotoSans-Regular.ttf
MONO      := /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all theme install uninstall deb clean

all:
	@echo "Targets: theme, install, uninstall, deb, clean"
	@echo "Needs grub-common (grub-mkfont), fonts-noto-core, fonts-dejavu-core, python3-cairo"

theme:
	python3 -I gen-grub.py $(BUILD)/theme
	cp theme/theme.txt $(BUILD)/theme/
	for s in 16 20; do grub-mkfont -s $$s -r $(RANGE) -o $(BUILD)/theme/noto-sans-$$s.pf2 $(SANS); done
	grub-mkfont -s 16 -r $(RANGE) -o $(BUILD)/theme/dejavu-sans-mono-16.pf2 $(MONO)

install: theme
	install -d $(DESTDIR)$(THEME_DIR)
	install -m644 $(BUILD)/theme/* $(DESTDIR)$(THEME_DIR)/
	install -Dm644 uzunyx-grub.cfg $(DESTDIR)$(SYSCONFDIR)/default/grub.d/uzunyx-grub.cfg

uninstall:
	rm -rf $(DESTDIR)$(PREFIX)/share/uzunyx-grub
	rm -f $(DESTDIR)$(SYSCONFDIR)/default/grub.d/uzunyx-grub.cfg

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -m644 debian/conffiles debian/triggers $(BUILD)/root/DEBIAN/
	install -m755 debian/preinst debian/postinst debian/postrm $(BUILD)/root/DEBIAN/
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
