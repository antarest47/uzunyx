# The key Uzunyx's APT repository is signed with, and where it is (the
# repository itself is built by ../uzunyx-repo).
# uzunyx-archive-keyring.gpg is the public key, exported once with
# gpg --export 971A62FD88B6D53B860FB7DD05D19D028CE7A0BC.
NAME    := uzunyx-archive-keyring
VERSION := 0.1.0
PREFIX  ?= /usr
DESTDIR ?=

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install deb clean

all:
	@echo "Targets: install, deb, clean"

install:
	install -Dm644 uzunyx-archive-keyring.gpg $(DESTDIR)$(PREFIX)/share/keyrings/uzunyx-archive-keyring.gpg
	install -Dm644 uzunyx-archive.sources $(DESTDIR)/etc/apt/sources.list.d/uzunyx-archive.sources

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 README.md $(BUILD)/root/usr/share/doc/$(NAME)/README.md
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
