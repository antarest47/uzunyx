# Debian package for Lunyx (GPL-3.0-only), from a pinned commit of its own repo
# on GitHub: `make fetch` clones it next to this one the first time and fetches
# from LUNYX_URL. smbprotocol and
# pyspnego aren't in Debian, so their wheels (pure Python, checked by SHA256) go
# inside the package.
NAME         := lunyx
LUNYX_URL    ?= https://github.com/antarest47/lunyx.git
LUNYX_COMMIT := 44061e698418f0cedd4cfd803d0f2d7ee60d6a09
# The commit's date, so that versions go up: hashes alone don't sort (apt
# took +gita289fdd for newer than +git89081dd). The "." after "git" sorts
# after any letter, so this is newer than every earlier +git<hash>.
LUNYX_DATE   := 20261119
# The revision counts changes to this recipe on the same commit.
VERSION      := 0.1.0+git.$(LUNYX_DATE).$(shell echo $(LUNYX_COMMIT) | cut -c1-7)-1
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
	python3 fetch-wheels.py $(WHEELS)

# The files come from the pinned commit, not from whatever the checkout is on
# (it's the Lunyx working repo: it can be on another branch or have changes).
SRC := $(CURDIR)/$(BUILD)/src

check:
	git -C $(LUNYX_SRC) cat-file -e $(LUNYX_COMMIT)^{commit}

.PHONY: $(SRC)
$(SRC): check
	rm -rf $(SRC)
	mkdir -p $(SRC)
	git -C $(LUNYX_SRC) archive $(LUNYX_COMMIT) | tar -x -C $(SRC)

install: $(SRC)
	install -d $(DESTDIR)$(APP_DIR)/vendor
	install -m644 $(SRC)/*.py $(SRC)/logo.png $(SRC)/VERSION $(DESTDIR)$(APP_DIR)/
	for w in $(WHEELS)/*.whl; do python3 -m zipfile -e $$w $(DESTDIR)$(APP_DIR)/vendor/; done
	find $(DESTDIR)$(APP_DIR)/vendor -type d -exec chmod 755 {} +
	find $(DESTDIR)$(APP_DIR)/vendor -type f -exec chmod 644 {} +
	install -Dm755 lunyx $(DESTDIR)$(PREFIX)/bin/lunyx
	install -Dm644 $(SRC)/flatpak/$(APP_ID).desktop $(DESTDIR)$(PREFIX)/share/applications/$(APP_ID).desktop
	install -Dm644 $(SRC)/flatpak/lunyx-icon.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/512x512/apps/$(APP_ID).png
	install -Dm644 $(SRC)/THIRD_PARTY_LICENSES.md $(DESTDIR)$(PREFIX)/share/doc/$(NAME)/THIRD_PARTY_LICENSES.md
	install -Dm644 debian/copyright $(DESTDIR)$(PREFIX)/share/doc/$(NAME)/copyright

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	rm -rf $(SRC)
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
