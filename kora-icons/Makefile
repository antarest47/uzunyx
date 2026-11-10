# Debian package for the Kora icon theme (https://github.com/bikass/kora).
# Upstream has no releases, so the package pins a commit. The upstream tree
# (~55 MB, ~23k files) stays out of this repo: `make fetch` clones it next to
# it unless KORA_SRC points at an existing checkout.
NAME        := kora-icon-theme
KORA_URL    := https://github.com/bikass/kora
KORA_COMMIT := ba1e9e279aa5b3f6674ec6b17534ea05032de580
KORA_DATE   := 20260904
VERSION     := 0~$(KORA_DATE).git$(shell echo $(KORA_COMMIT) | cut -c1-7)
PREFIX      ?= /usr
DESTDIR     ?=

KORA_SRC ?= $(CURDIR)/../../kora-upstream
THEMES   := kora kora-pgrey
ICON_DIR := $(PREFIX)/share/icons

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all fetch check install uninstall deb clean

all:
	@echo "Targets: fetch, install, uninstall, deb, clean"

fetch:
	test -d $(KORA_SRC)/.git || git clone $(KORA_URL) $(KORA_SRC)
	git -C $(KORA_SRC) fetch --quiet --depth 1 origin $(KORA_COMMIT) || true
	git -C $(KORA_SRC) checkout --quiet $(KORA_COMMIT)

# The checkout must be exactly the pinned commit.
check:
	test "$$(git -C $(KORA_SRC) rev-parse HEAD)" = "$(KORA_COMMIT)"
	test -z "$$(git -C $(KORA_SRC) status --porcelain)"

# Copies the themes (symlinks kept), dropping upstream's cache helper script
# and its stale icon-theme.cache, and normalising permissions (upstream has
# executable bits on some SVGs).
install: check
	install -d $(DESTDIR)$(ICON_DIR)
	for t in $(THEMES); do \
		rm -rf $(DESTDIR)$(ICON_DIR)/$$t; \
		cp -a $(KORA_SRC)/$$t $(DESTDIR)$(ICON_DIR)/$$t; \
		rm -f $(DESTDIR)$(ICON_DIR)/$$t/create-new-icon-theme.cache.sh $(DESTDIR)$(ICON_DIR)/$$t/icon-theme.cache; \
		find $(DESTDIR)$(ICON_DIR)/$$t -type d -exec chmod 755 {} +; \
		find $(DESTDIR)$(ICON_DIR)/$$t -type f -exec chmod 644 {} +; \
	done
	install -Dm644 $(KORA_SRC)/LICENSE $(DESTDIR)$(PREFIX)/share/doc/$(NAME)/LICENSE
	install -Dm644 debian/copyright $(DESTDIR)$(PREFIX)/share/doc/$(NAME)/copyright

uninstall:
	for t in $(THEMES); do rm -rf $(DESTDIR)$(ICON_DIR)/$$t; done
	rm -rf $(DESTDIR)$(PREFIX)/share/doc/$(NAME)

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	dpkg-deb --root-owner-group -Zxz --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
