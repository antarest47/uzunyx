NAME    := uzunyx-doctor
VERSION := 0.1.21
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all test install uninstall deb clean

all:
	@echo "Targets: test, install, uninstall, deb, clean"

test:
	python3 -I test_doctor.py

install:
	install -Dm755 $(NAME) $(DESTDIR)$(PREFIX)/bin/$(NAME)
	install -Dm644 org.uzunyx.doctor.desktop $(DESTDIR)$(PREFIX)/share/applications/org.uzunyx.doctor.desktop
	install -Dm644 $(NAME)-login.desktop $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/$(NAME)-login.desktop

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(NAME)
	rm -f $(DESTDIR)$(PREFIX)/share/applications/org.uzunyx.doctor.desktop
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/$(NAME)-login.desktop

deb: clean test
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
