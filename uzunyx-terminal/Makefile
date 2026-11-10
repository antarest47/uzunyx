# Terminal of Uzunyx: zsh with Oh My Zsh, Starship, zsh-autocomplete
# and fastfetch with the logo. Oh My Zsh is not in Debian and has no releases,
# and zsh-autocomplete neither: the package pins their commits; `make fetch`
# clones them next to this repo.
NAME       := uzunyx-terminal
OMZ_URL    := https://github.com/ohmyzsh/ohmyzsh.git
OMZ_COMMIT := 17a2b4c3a5855524ad4772a17ada0dc474e2fdf3
AC_URL     := https://github.com/marlonrichert/zsh-autocomplete.git
AC_COMMIT  := 52ce8176d280d58a4a2af6a829d2266fffae568c
VERSION    := 0.7.0
PREFIX     ?= /usr
SYSCONFDIR ?= /etc
DESTDIR    ?=

OMZ_SRC ?= $(CURDIR)/../../ohmyzsh-upstream
AC_SRC  ?= $(CURDIR)/../../zsh-autocomplete-upstream
SHARE   := $(PREFIX)/share/$(NAME)

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all fetch logo starship install deb clean

all:
	@echo "Targets: fetch, logo, install, deb, clean"

fetch:
	test -d $(OMZ_SRC)/.git || git clone $(OMZ_URL) $(OMZ_SRC)
	git -C $(OMZ_SRC) fetch --quiet --depth 1 origin $(OMZ_COMMIT) || true
	git -C $(OMZ_SRC) checkout --quiet $(OMZ_COMMIT)
	test -d $(AC_SRC)/.git || git clone $(AC_URL) $(AC_SRC)
	git -C $(AC_SRC) checkout --quiet $(AC_COMMIT)

logo:
	./gen-logo.py ../icons/uzunyx-icon-akane.png fastfetch/logo.txt

starship:
	./gen-starship.py starship

install:
	test "$$(git -C $(OMZ_SRC) rev-parse HEAD)" = "$(OMZ_COMMIT)"
	test "$$(git -C $(AC_SRC) rev-parse HEAD)" = "$(AC_COMMIT)"
	install -Dm644 zsh/.zshenv $(DESTDIR)$(SHARE)/zsh/.zshenv
	install -Dm644 zsh/.zshrc $(DESTDIR)$(SHARE)/zsh/.zshrc
	install -Dm644 servicemenus/uzunyx-open-terminal.desktop $(DESTDIR)$(PREFIX)/share/kio/servicemenus/uzunyx-open-terminal.desktop
	install -Dm644 uzunyx-terminal-env.sh $(DESTDIR)$(SYSCONFDIR)/xdg/plasma-workspace/env/uzunyx-terminal.sh
	# The prompt's round caps, made to Hack's cell (needs python3-fonttools).
	install -d $(DESTDIR)$(PREFIX)/share/fonts/truetype/uzunyx-powerline
	python3 -I gen-powerline-font.py $(DESTDIR)$(PREFIX)/share/fonts/truetype/uzunyx-powerline/UzunyxPowerline.ttf
	chmod 644 $(DESTDIR)$(PREFIX)/share/fonts/truetype/uzunyx-powerline/UzunyxPowerline.ttf
	install -Dm644 fontconfig/60-uzunyx-powerline.conf $(DESTDIR)$(PREFIX)/share/fontconfig/conf.avail/60-uzunyx-powerline.conf
	install -d $(DESTDIR)$(SYSCONFDIR)/fonts/conf.d
	ln -sf ../../../usr/share/fontconfig/conf.avail/60-uzunyx-powerline.conf $(DESTDIR)$(SYSCONFDIR)/fonts/conf.d/60-uzunyx-powerline.conf
	install -Dm644 starship/akane.toml $(DESTDIR)$(SHARE)/starship/akane.toml
	install -Dm644 starship/sora.toml $(DESTDIR)$(SHARE)/starship/sora.toml
	install -Dm644 fastfetch/logo.txt $(DESTDIR)$(SHARE)/logo.txt
	install -Dm644 fastfetch/config.jsonc $(DESTDIR)$(SYSCONFDIR)/xdg/fastfetch/config.jsonc
	install -d $(DESTDIR)$(SHARE)/zsh-autocomplete
	cp -r $(AC_SRC)/Completions $(AC_SRC)/Functions $(AC_SRC)/z-async $(AC_SRC)/zsh-autocomplete.plugin.zsh $(AC_SRC)/LICENSE $(DESTDIR)$(SHARE)/zsh-autocomplete/
	install -d $(DESTDIR)$(SHARE)/oh-my-zsh
	cp -r $(OMZ_SRC)/lib $(OMZ_SRC)/plugins $(OMZ_SRC)/tools $(OMZ_SRC)/oh-my-zsh.sh $(OMZ_SRC)/LICENSE.txt $(DESTDIR)$(SHARE)/oh-my-zsh/
	install -d $(DESTDIR)$(SHARE)/oh-my-zsh/themes
	# compinit rejects group-writable folders owned by root.
	chmod -R u=rwX,go=rX $(DESTDIR)$(SHARE)

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	install -Dm644 README.md $(BUILD)/root/usr/share/doc/$(NAME)/README.md
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
