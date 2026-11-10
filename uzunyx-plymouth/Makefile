# Boot splash (Plymouth) themes, one per edition: uzunyx-akane (the default)
# and uzunyx-sora. Same script (uzunyx.script); gen-theme.py makes each
# edition's images (logo, icon, the shine frames that sweep over the name,
# glint, password field). Also adds "splash" to the kernel command line
# through /etc/default/grub.d, so the theme is shown.
NAME    := uzunyx-plymouth
VERSION := 0.2.2
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

EDITIONS   := akane sora
THEMES_DIR := $(PREFIX)/share/plymouth/themes

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all images preview install uninstall deb clean

all:
	@echo "Targets: images, preview, install, uninstall, deb, clean"
	@echo "Needs python3-cairo; preview also needs imagemagick"

images:
	for e in $(EDITIONS); do python3 -I gen-theme.py $$e $(BUILD)/$$e; done

# Animated WebP of each edition (one loop) and a still with the password
# field, from the same layout and timing as uzunyx.script.
preview: images
	set -e; for e in $(EDITIONS); do \
		python3 -I preview.py $(BUILD)/$$e $(BUILD)/preview-$$e; \
		python3 -I preview.py $(BUILD)/$$e $(BUILD)/still-$$e --password; \
		magick -delay 4 $$(for k in $$(seq 12 102); do printf '$(BUILD)/preview-%s/frame-%03d.png ' $$e $$k; done) \
			-resize 1280x -loop 0 -quality 90 $(BUILD)/uzunyx-$$e.webp; \
	done

install: images
	set -e; for e in $(EDITIONS); do \
		d=$(DESTDIR)$(THEMES_DIR)/uzunyx-$$e; \
		install -d $$d; \
		install -m644 $(BUILD)/$$e/*.png uzunyx.script $$d/; \
		sed "s/@EDITION@/$$e/g; s/@Edition@/$$(echo $$e | sed 's/^./\U&/')/g; s|@DIR@|$(THEMES_DIR)/uzunyx-$$e|g" \
			uzunyx.plymouth.in > $$d/uzunyx-$$e.plymouth; \
		chmod 644 $$d/uzunyx-$$e.plymouth; \
	done
	install -Dm644 grub-splash.cfg $(DESTDIR)$(SYSCONFDIR)/default/grub.d/uzunyx-splash.cfg

uninstall:
	rm -rf $(addprefix $(DESTDIR)$(THEMES_DIR)/uzunyx-,$(EDITIONS))
	rm -f $(DESTDIR)$(SYSCONFDIR)/default/grub.d/uzunyx-splash.cfg

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -m644 debian/conffiles debian/triggers $(BUILD)/root/DEBIAN/
	install -m755 debian/postinst debian/postrm $(BUILD)/root/DEBIAN/
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
