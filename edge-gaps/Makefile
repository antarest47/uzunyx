NAME    := edge-gaps
VERSION := 0.5.2
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	install -Dm755 $(NAME) $(DESTDIR)$(PREFIX)/bin/$(NAME)
	install -Dm755 uzunyx-mode $(DESTDIR)$(PREFIX)/bin/uzunyx-mode
	install -Dm644 $(NAME).desktop $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/$(NAME).desktop
	install -Dm644 $(NAME)rc $(DESTDIR)$(SYSCONFDIR)/xdg/$(NAME)rc

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(NAME) $(DESTDIR)$(PREFIX)/bin/uzunyx-mode
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/$(NAME).desktop
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/$(NAME)rc

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
