# Metapackage: installs the whole Uzunyx desktop. The pieces that are pinned
# to one KWin version (the C++ effects) and the ones that change how the PC
# boots (Plymouth, GRUB) are Recommends: apt installs them by default, but
# they can be left out or removed (e.g. while a KWin update waits for the
# effects to be rebuilt) without taking the rest away.
NAME    := uzunyx-desktop
VERSION := 0.1.20

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all deb clean

all:
	@echo "Targets: deb, clean"

deb: clean
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 README.md $(BUILD)/root/usr/share/doc/$(NAME)/README.md
	install -Dm644 zram/uzunyx.conf $(BUILD)/root/usr/lib/systemd/zram-generator.conf.d/uzunyx.conf
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
