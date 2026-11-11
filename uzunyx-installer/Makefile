# One .deb that installs Uzunyx on a normal Debian: it carries every Uzunyx
# package in a small APT repository and the uzunyx-install command, which moves
# the system to the Debian release Uzunyx is built for and installs the desktop.
# Collects the .deb of each folder as it is: run `make deb` there first.
NAME    := uzunyx-installer
VERSION := 0.1.8

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb
ROOT  := $(BUILD)/root
REPO  := $(ROOT)/usr/share/$(NAME)/repo

# Folders with a package that goes in the repository.
FOLDERS := edge-gaps kora-icons lunyx uzunyx-archive-keyring uzunyx-buttons uzunyx-clock \
	uzunyx-altguard uzunyx-colors uzunyx-controlcenter uzunyx-deco uzunyx-desktop \
	uzunyx-editions uzunyx-genie uzunyx-grub uzunyx-keys uzunyx-welcome uzunyx-lnf \
	uzunyx-lockkeys uzunyx-logout uzunyx-openclose uzunyx-outline uzunyx-pager \
	uzunyx-plasmatheme uzunyx-plymouth uzunyx-shortcuts uzunyx-tasks \
	uzunyx-terminal uzunyx-tiling uzunyx-timer uzunyx-wallpapers \
	../tsunyx-launcher

.PHONY: all deb clean

all:
	@echo "Targets: deb, clean"

deb: clean
	install -d $(REPO)
	for f in $(FOLDERS); do \
		v=$$($(MAKE) -s -C ../$$f --eval='_pv:;@echo $$(VERSION)' _pv); \
		d=$$(ls -v ../$$f/build/*_$$v*.deb 2>/dev/null | tail -1); \
		[ -n "$$d" ] || { echo "$$f: falta el .deb de $$v (make deb)"; exit 1; }; \
		cp "$$d" $(REPO)/; \
	done
	cd $(REPO) && apt-ftparchive packages . > Packages && apt-ftparchive release . > Release
	install -Dm755 uzunyx-install $(ROOT)/usr/sbin/uzunyx-install
	install -Dm644 uzunyx.sources $(ROOT)/etc/apt/sources.list.d/uzunyx.sources
	install -Dm644 README.md $(ROOT)/usr/share/doc/$(NAME)/README.md
	install -Dm644 debian/control $(ROOT)/DEBIAN/control
	install -Dm644 debian/conffiles $(ROOT)/DEBIAN/conffiles
	install -Dm755 debian/postinst $(ROOT)/DEBIAN/postinst
	sed -i 's/@VERSION@/$(VERSION)/' $(ROOT)/DEBIAN/control
	install -Dm644 ../tools/copyright $(ROOT)/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(ROOT) $(DEB)

clean:
	rm -rf $(BUILD)
