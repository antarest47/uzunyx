# Debian package for Lunyx (GPL-3.0-only), from a pinned commit of its own repo
# on GitHub: `make fetch` clones it next to this one the first time and fetches
# from LUNYX_URL. smbprotocol and
# pyspnego aren't in Debian, so their wheels (pure Python, checked by SHA256) go
# inside the package.
NAME         := lunyx
LUNYX_URL    ?= https://github.com/antarest47/lunyx.git
LUNYX_COMMIT := 75a7169cce0d48e17467bab1850acbf478253ef6
# The revision counts changes to this recipe on the same commit.
VERSION      := 0.1.0+git$(shell echo $(LUNYX_COMMIT) | cut -c1-7)-1
PREFIX       ?= /usr
DESTDIR      ?=

LUNYX_SRC ?= $(CURDIR)/../../lunyx
APP_ID    := io.github.antarest47.Lunyx
APP_DIR   := $(PREFIX)/share/lunyx
WHEELS    := $(CURDIR)/wheels-cache

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all fetch check install deb clean

all:
	@echo "Targets: fetch, install, deb, clean"

fetch:
	test -d $(LUNYX_SRC)/.git || git clone $(LUNYX_URL) $(LUNYX_SRC)
	git -C $(LUNYX_SRC) fetch --quiet $(LUNYX_URL)
	git -C $(LUNYX_SRC) checkout --quiet $(LUNYX_COMMIT)
	python3 fetch-wheels.py $(WHEELS)

# The checkout must be exactly the pinned commit.
check:
	test "$$(git -C $(LUNYX_SRC) rev-parse HEAD)" = "$(LUNYX_COMMIT)"
	test -z "$$(git -C $(LUNYX_SRC) status --porcelain)"

install: check
	install -d $(DESTDIR)$(APP_DIR)/vendor
	install -m644 $(LUNYX_SRC)/*.py $(LUNYX_SRC)/logo.png $(LUNYX_SRC)/VERSION $(DESTDIR)$(APP_DIR)/
	for w in $(WHEELS)/*.whl; do python3 -m zipfile -e $$w $(DESTDIR)$(APP_DIR)/vendor/; done
	find $(DESTDIR)$(APP_DIR)/vendor -type d -exec chmod 755 {} +
	find $(DESTDIR)$(APP_DIR)/vendor -type f -exec chmod 644 {} +
	install -Dm755 lunyx $(DESTDIR)$(PREFIX)/bin/lunyx
	install -Dm644 $(LUNYX_SRC)/flatpak/$(APP_ID).desktop $(DESTDIR)$(PREFIX)/share/applications/$(APP_ID).desktop
	install -Dm644 $(LUNYX_SRC)/flatpak/lunyx-icon.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/512x512/apps/$(APP_ID).png
	install -Dm644 $(LUNYX_SRC)/THIRD_PARTY_LICENSES.md $(DESTDIR)$(PREFIX)/share/doc/$(NAME)/THIRD_PARTY_LICENSES.md
	install -Dm644 debian/copyright $(DESTDIR)$(PREFIX)/share/doc/$(NAME)/copyright

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
