NAME    := uzunyx-welcome
VERSION := 0.4.0
PREFIX  ?= /usr
DESTDIR ?=

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install deb clean

all:
	@echo "Targets: install, deb, clean"

install:
	install -Dm755 uzunyx-welcome $(DESTDIR)$(PREFIX)/bin/uzunyx-welcome
	install -Dm644 control-center.png $(DESTDIR)$(PREFIX)/share/uzunyx-welcome/control-center.png
	install -Dm644 -t $(DESTDIR)$(PREFIX)/share/uzunyx-welcome art/*.png
	install -Dm644 org.uzunyx.welcome.desktop $(DESTDIR)$(PREFIX)/share/applications/org.uzunyx.welcome.desktop
	install -Dm644 uzunyx-welcome-autostart.desktop $(DESTDIR)/etc/xdg/autostart/uzunyx-welcome.desktop
	install -Dm644 /dev/null $(DESTDIR)/etc/skel/.config/uzunyx/welcome-pending
	install -Dm644 plasma-welcomerc $(DESTDIR)/etc/xdg/plasma-welcomerc

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 README.md $(BUILD)/root/usr/share/doc/$(NAME)/README.md
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
