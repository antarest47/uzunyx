NAME    := uzunyx-tasks
VERSION := 0.4.7
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

PLASMOID     := org.uzunyx.tasks
PLASMOID_DIR := $(PREFIX)/share/plasma/plasmoids/$(PLASMOID)

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	(cd package && find . -type f -exec install -Dm644 {} $(DESTDIR)$(PLASMOID_DIR)/{} \;)
	install -Dm755 uzunyx-task-badges $(DESTDIR)$(PREFIX)/libexec/uzunyx-task-badges
	install -Dm644 uzunyx-task-badges.desktop $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/uzunyx-task-badges.desktop

uninstall:
	rm -rf $(DESTDIR)$(PLASMOID_DIR)
	rm -f $(DESTDIR)$(PREFIX)/libexec/uzunyx-task-badges
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/uzunyx-task-badges.desktop

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
