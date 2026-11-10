NAME    := uzunyx-keys
VERSION := 0.1.7
PREFIX  ?= /usr
DESTDIR ?=

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install deb clean

all:
	@echo "Targets: install, deb, clean"

install:
	install -Dm755 uzunyx-keys $(DESTDIR)$(PREFIX)/bin/uzunyx-keys
	install -Dm644 org.uzunyx.keys.desktop $(DESTDIR)$(PREFIX)/share/applications/org.uzunyx.keys.desktop

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
