# Live and installable Uzunyx ISO (BIOS and UEFI), built without root.
# Needs: mmdebstrap uidmap squashfs-tools xorriso mtools grub-pc-bin
# grub-efi-amd64-bin, subuid/subgid for the user, and uzunyx-installer built.
VERSION := 0.2.0
# rclone remote and bucket for make publish (Cloudflare R2).
REMOTE ?= CloudflareR2:uzunyx
# GitHub repository whose release v$(VERSION) carries the sources.
GITHUB ?= antarest47/uzunyx

.PHONY: all calamares iso publish test test-fresh test-installed vm-delete clean

all:
	@echo "Targets: calamares, iso, publish, test, clean"

# Calamares with the patched partition legend; iso needs its .deb.
calamares:
	./build-calamares.sh

iso:
	./build-iso.sh $(VERSION)

# Sources to the GitHub release v$(VERSION), then the ISO to $(REMOTE)/iso/$(VERSION)/.
publish:
	./publish.sh $(VERSION) $(REMOTE) $(GITHUB)

# Boots the ISO in a VM with an empty disk (test-vm.sh bios for BIOS).
test:
	./test-vm.sh

test-fresh:
	./test-vm.sh --fresh

test-installed:
	./test-vm.sh --installed

vm-delete:
	./test-vm.sh --delete

clean:
	rm -rf build
