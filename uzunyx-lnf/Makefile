NAME    := uzunyx-lookandfeel
VERSION := 0.28.1
PREFIX  ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

LNFS_DIR := $(PREFIX)/share/plasma/look-and-feel
FILES   := contents/previews/preview.png contents/previews/fullscreenpreview.jpg \
           contents/logout/Logout.qml contents/logout/LogoutButton.qml contents/logout/timer.js
# package/ is the Akane edition (id org.uzunyx.desktop, the default since
# before there were editions). Sora is generated from it:
# id : name : color scheme : wallpaper : launcher logo : colour (en, es) :
# accent (the splash's glints, from uzunyx-colors) : icon theme (folders,
# from uzunyx-buttons)
EDITIONS := org.uzunyx.desktop:Akane:UzunyxAkane:UzunyxAkane:uzunyx-akane:crimson:carmesí:E62967:uzunyx \
            org.uzunyx.sora:Sora:UzunyxSora:UzunyxSora:uzunyx-sora:cyan:cian:16CDE0:uzunyx-sora
# Launcher logos (repo's icons/), installed as hicolor app icons
LOGOS    := uzunyx-akane:../icons/uzunyx-icon-akane.png uzunyx-sora:../icons/uzunyx-icon-sora.png
HICOLOR  := $(PREFIX)/share/icons/hicolor

LOCKDIR := $(PREFIX)/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen

AVATARS := $(PREFIX)/share/plasma/avatars

BUILD := build
DEB   := $(BUILD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all install uninstall deb clean

all:
	@echo "Targets: install, uninstall, deb, clean"

install:
	set -e; for e in $(EDITIONS); do \
		set -- $$(echo $$e | tr ':' ' '); id=$$1; name=$$2; scheme=$$3; wall=$$4; logo=$$5; en=$$6; es=$$7; accent=$$8; icons=$$9; \
		d=$(DESTDIR)$(LNFS_DIR)/$$id; \
		for f in $(FILES); do install -Dm644 package/$$f $$d/$$f; done; \
		install -d $$d/contents/layouts; \
		sed -e "s/\"Id\": \"org.uzunyx.desktop\"/\"Id\": \"$$id\"/" -e "s/Akane/$$name/g" \
			-e "s/(crimson)/($$en)/" -e "s/(carmesí)/($$es)/" \
			package/metadata.json > $$d/metadata.json; \
		sed -e "s/^ColorScheme=.*/ColorScheme=$$scheme/" -e "s/^Image=.*/Image=$$wall/" \
			-e "/^\[ksplashrc\]/,/^\[/s/^Theme=.*/Theme=$$id/" \
			-e "/^\[kdeglobals\]\[Icons\]/,/^\[/s/^Theme=.*/Theme=$$icons/" \
			package/contents/defaults > $$d/contents/defaults; \
		install -Dm644 package/contents/splash/Splash.qml $$d/contents/splash/Splash.qml; \
		ed=$$(echo $$name | tr A-Z a-z); \
		[ ! -d previews-$$ed ] || install -m644 previews-$$ed/* $$d/contents/previews/; \
		python3 -I gen-splash.py ../icons/uzunyx-icon-$$ed.png ../uzunyx-plymouth/art/uzunyx-logo-$$ed.png \
			"#$$accent" $$d/contents/splash/images; \
		sed -e "s/\"uzunyx-akane\"/\"$$logo\"/" package/contents/layouts/org.kde.plasma.desktop-layout.js \
			> $$d/contents/layouts/org.kde.plasma.desktop-layout.js; \
		chmod 644 $$d/metadata.json $$d/contents/defaults $$d/contents/layouts/*.js; \
	done
	for l in $(LOGOS); do python3 gen-logos.py $${l#*:} $${l%%:*} $(DESTDIR)$(HICOLOR); done
	install -Dm644 kdeglobals $(DESTDIR)$(SYSCONFDIR)/xdg/kdeglobals
	# Lock screen buttons; LockScreenUi.qml is made in postinst from Plasma's.
	install -Dm644 lockscreen/UzunyxActionButton.qml $(DESTDIR)$(LOCKDIR)/UzunyxActionButton.qml
	install -Dm644 lockscreen/ball.svg $(DESTDIR)$(LOCKDIR)/ball.svg
	# The default avatar, instead of Debian's (diverted in preinst).
	python3 -I gen-avatar.py ../wallpapers/akane-profile.png $(DESTDIR)$(SYSCONFDIR)/skel/.face 256
	install -d $(DESTDIR)$(PREFIX)/share/sddm/faces
	cp $(DESTDIR)$(SYSCONFDIR)/skel/.face $(DESTDIR)$(PREFIX)/share/sddm/faces/.face.icon
	# Choices in System Settings > Users.
	python3 -I gen-avatar.py ../wallpapers/akane-profile.png "$(DESTDIR)$(AVATARS)/Uzunyx Akane.png" 512
	python3 -I gen-avatar.py ../wallpapers/sora-profile.png "$(DESTDIR)$(AVATARS)/Uzunyx Sora.png" 512
	python3 -I gen-avatar.py ../icons/uzunyx-icon-akane.png "$(DESTDIR)$(AVATARS)/Uzunyx Akane (logo).png" 512
	python3 -I gen-avatar.py ../icons/uzunyx-icon-sora.png "$(DESTDIR)$(AVATARS)/Uzunyx Sora (logo).png" 512
	install -Dm644 mimeapps.list $(DESTDIR)$(SYSCONFDIR)/xdg/mimeapps.list
	install -Dm644 dolphin/dolphinui.rc $(DESTDIR)$(PREFIX)/share/kxmlgui5/dolphin/dolphinui.rc
	install -Dm644 uzunyx-lookandfeel-env.sh $(DESTDIR)$(SYSCONFDIR)/xdg/plasma-workspace/env/uzunyx-lookandfeel.sh

uninstall:
	for e in $(EDITIONS); do rm -rf $(DESTDIR)$(LNFS_DIR)/$${e%%:*}; done
	for l in $(LOGOS); do rm -f $(DESTDIR)$(HICOLOR)/*/apps/$${l%%:*}.png; done
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/kdeglobals $(DESTDIR)$(SYSCONFDIR)/skel/.face $(DESTDIR)$(PREFIX)/share/sddm/faces/.face.icon
	rm -f "$(DESTDIR)$(AVATARS)"/Uzunyx*.png
	rm -f $(DESTDIR)$(LOCKDIR)/UzunyxActionButton.qml $(DESTDIR)$(LOCKDIR)/ball.svg
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/mimeapps.list
	rm -f $(DESTDIR)$(SYSCONFDIR)/xdg/plasma-workspace/env/uzunyx-lookandfeel.sh
	rm -f $(DESTDIR)$(PREFIX)/share/kxmlgui5/dolphin/dolphinui.rc

deb: clean
	$(MAKE) install DESTDIR=$(CURDIR)/$(BUILD)/root PREFIX=/usr SYSCONFDIR=/etc
	install -Dm644 debian/control $(BUILD)/root/DEBIAN/control
	install -m755 debian/preinst debian/postinst debian/postrm $(BUILD)/root/DEBIAN/
	install -m644 debian/triggers $(BUILD)/root/DEBIAN/
	install -Dm644 debian/conffiles $(BUILD)/root/DEBIAN/conffiles
	sed -i 's/@VERSION@/$(VERSION)/' $(BUILD)/root/DEBIAN/control
	install -Dm644 ../tools/copyright $(BUILD)/root/usr/share/doc/$(NAME)/copyright
	dpkg-deb --root-owner-group --build $(BUILD)/root $(DEB)

clean:
	rm -rf $(BUILD)
