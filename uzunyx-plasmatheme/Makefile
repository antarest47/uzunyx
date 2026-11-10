NAME    := uzunyx-plasmatheme
VERSION := 0.8.1
PREFIX  ?= /usr
DESTDIR ?=

THEME_DIR := $(PREFIX)/share/plasma/desktoptheme/uzunyx
# Panel background in every opacity variant (the panel picks one by its setting).
PANEL_VARIANTS := widgets opaque/widgets translucent/widgets solid/widgets
# Background of Plasma's popups (notifications, tooltips...), with the same outline.
DIALOG_VARIANTS := dialogs opaque/dialogs translucent/dialogs solid/dialogs
FILES     := metadata.json plasmarc widgets/tasks.svgz $(foreach v,$(PANEL_VARIANTS),$(v)/panel-background.svgz) $(foreach v,$(DIALOG_VARIANTS),$(v)/background.svgz)
# Sources for regenerating the widgets (Breeze's own, from libplasma).
BREEZE_TASKS ?= /usr/share/plasma/desktoptheme/default/widgets/tasks.svgz
BREEZE_THEME ?= /usr/share/plasma/desktoptheme/default

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all svg install uninstall deb clean

all:
	@echo "Targets: svg, install, uninstall, deb, clean"

# Regenerate package/widgets/*.svgz from Breeze's.
svg:
	mkdir -p $(BUILD)
	gunzip -c $(BREEZE_TASKS) > $(BUILD)/breeze-tasks.svg
	./gen-tasks-svg.py $(BUILD)/breeze-tasks.svg $(BUILD)/tasks.svg
	gzip -9n -c $(BUILD)/tasks.svg > package/widgets/tasks.svgz
	for v in $(PANEL_VARIANTS); do \
		mkdir -p $(BUILD)/$$v package/$$v && \
		gunzip -c $(BREEZE_THEME)/$$v/panel-background.svgz > $(BUILD)/$$v/breeze-panel-background.svg && \
		./gen-panel-svg.py $(BUILD)/$$v/breeze-panel-background.svg $(BUILD)/$$v/panel-background.svg && \
		gzip -9n -c $(BUILD)/$$v/panel-background.svg > package/$$v/panel-background.svgz || exit 1; \
	done
	for v in $(DIALOG_VARIANTS); do \
		mkdir -p $(BUILD)/$$v package/$$v && \
		gunzip -c $(BREEZE_THEME)/$$v/background.svgz > $(BUILD)/$$v/breeze-background.svg && \
		./gen-panel-svg.py $(BUILD)/$$v/breeze-background.svg $(BUILD)/$$v/background.svg && \
		gzip -9n -c $(BUILD)/$$v/background.svg > package/$$v/background.svgz || exit 1; \
	done

install:
	for f in $(FILES); do install -Dm644 package/$$f $(DESTDIR)$(THEME_DIR)/$$f; done

uninstall:
	rm -rf $(DESTDIR)$(THEME_DIR)

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
