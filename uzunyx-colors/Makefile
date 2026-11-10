NAME    := uzunyx-colors
VERSION := 0.3.1
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

SCHEMES_DIR := $(PREFIX)/share/color-schemes
SCHEMES     := UzunyxAkane UzunyxSora
KONSOLE_DIR := $(PREFIX)/share/konsole

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all colors install uninstall deb clean

all:
	@echo "Targets: colors, install, uninstall, deb, clean"

# Regenerate color-schemes/*.colors and konsole/* from the palettes in gen-colors.py.
colors:
	./gen-colors.py color-schemes konsole

install:
	for s in $(SCHEMES); do install -Dm644 color-schemes/$$s.colors $(DESTDIR)$(SCHEMES_DIR)/$$s.colors; done
	for s in $(SCHEMES); do \
		install -Dm644 konsole/$$s.colorscheme $(DESTDIR)$(KONSOLE_DIR)/$$s.colorscheme; \
		install -Dm644 konsole/$$s.profile $(DESTDIR)$(KONSOLE_DIR)/$$s.profile; \
	done
	install -Dm644 konsolerc $(DESTDIR)$(SYSCONFDIR)/xdg/konsolerc

uninstall:
	for s in $(SCHEMES); do rm -f $(DESTDIR)$(SCHEMES_DIR)/$$s.colors $(DESTDIR)$(KONSOLE_DIR)/$$s.colorscheme $(DESTDIR)$(KONSOLE_DIR)/$$s.profile; done
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/konsolerc

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
