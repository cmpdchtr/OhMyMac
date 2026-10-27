# SPDX-License-Identifier: GPL-3.0-or-later
# OhMyMac — developer and packager entry points.

PREFIX  ?= /usr
DESTDIR ?=
BUILD   ?= build

.PHONY: all build install install-user uninstall-user lint test clean dist help

all: build

help:
	@echo "make build          Compile the Sass sources into $(BUILD)/"
	@echo "make install        Stage themes under DESTDIR (packagers)"
	@echo "make install-user   Run ./install.sh for the current user"
	@echo "make lint           shellcheck + Sass build"
	@echo "make test           lint + unit tests + dry-run install"
	@echo "make dist           Source tarball with prebuilt CSS"

build:
	@OHM_BUILD="$(abspath $(BUILD))" bash -c '. lib/loader.sh && build_themes'

install: build
	install -d "$(DESTDIR)$(PREFIX)/share/themes"
	cp -a "$(BUILD)/OhMyMac-Light" "$(BUILD)/OhMyMac-Dark" "$(DESTDIR)$(PREFIX)/share/themes/"
	@for v in Light Dark; do \
	  OHM_BUILD="$(abspath $(BUILD))" bash -c '. lib/loader.sh && shell_finalize "$$1" "$$2"' _ \
	    "$(DESTDIR)$(PREFIX)/share/themes/OhMyMac-$$v" "$$v"; \
	done
	install -Dm755 bin/ohmymac-sync "$(DESTDIR)$(PREFIX)/bin/ohmymac-sync"
	install -Dm644 "$(BUILD)/libadwaita/gtk.css" "$(DESTDIR)$(PREFIX)/share/ohmymac/libadwaita/gtk.css"
	install -Dm644 -t "$(DESTDIR)$(PREFIX)/share/backgrounds/ohmymac" src/wallpapers/*.svg
	sed "s|@DIR@|$(PREFIX)/share/backgrounds/ohmymac|g" src/wallpapers/ohmymac.xml.in | \
	  install -Dm644 /dev/stdin "$(DESTDIR)$(PREFIX)/share/gnome-background-properties/ohmymac.xml"

install-user:
	./install.sh

uninstall-user:
	./uninstall.sh

lint:
	shellcheck -x install.sh uninstall.sh bin/ohmymac-sync lib/*.sh tests/*.sh
	$(MAKE) build

test: lint
	bash tests/run.sh

dist: build
	@v=$$(cat VERSION); \
	git archive --format=tar --prefix=OhMyMac-$$v/ HEAD > OhMyMac-$$v.tar && \
	tar --transform "s|^|OhMyMac-$$v/|" -rf OhMyMac-$$v.tar $(BUILD) && \
	xz -f OhMyMac-$$v.tar && echo "OhMyMac-$$v.tar.xz"

clean:
	rm -rf "$(BUILD)" OhMyMac-*.tar.xz
