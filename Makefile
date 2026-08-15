SWIFT := /Library/Developer/CommandLineTools/usr/bin/swift
ENV := DEVELOPER_DIR=/Library/Developer/CommandLineTools
BINARY := .build/debug/PullTimer
BINARY_RELEASE := .build/release/PullTimer
APP_DIR := PullTimer.app/Contents
MACOS_DIR := $(APP_DIR)/MacOS
INFO_PLIST := Info.plist

.PHONY: all build bundle run clean release dmg

VERSION := 1.0
DMG := website/downloads/PullTimer.dmg

all: bundle

build:
	$(ENV) $(SWIFT) build

bundle: build
	@mkdir -p $(MACOS_DIR) $(APP_DIR)/Resources
	@cp $(BINARY) $(MACOS_DIR)/PullTimer
	@cp $(INFO_PLIST) $(APP_DIR)/Info.plist
	@cp AppIcon.icns $(APP_DIR)/Resources/AppIcon.icns
	@codesign --force --deep --sign - --identifier "com.pulltimer.app" PullTimer.app
	@echo "App bundle created and signed at PullTimer.app"

run: bundle
	@pkill -x PullTimer 2>/dev/null || true
	@sleep 0.3
	@open PullTimer.app

clean:
	@rm -rf .build PullTimer.app .dmg-root

release:
	$(ENV) $(SWIFT) build -c release
	@mkdir -p $(MACOS_DIR) $(APP_DIR)/Resources
	@cp $(BINARY_RELEASE) $(MACOS_DIR)/PullTimer
	@cp $(INFO_PLIST) $(APP_DIR)/Info.plist
	@cp AppIcon.icns $(APP_DIR)/Resources/AppIcon.icns
	@codesign --force --deep --sign - --identifier "com.pulltimer.app" PullTimer.app
	@echo "Release bundle at PullTimer.app"

dmg: release
	@rm -rf .dmg-root
	@mkdir -p .dmg-root website/downloads
	@cp -R PullTimer.app .dmg-root/
	@ln -s /Applications .dmg-root/Applications
	@rm -f $(DMG)
	@hdiutil create -volname "PullTimer $(VERSION)" -srcfolder .dmg-root -ov -format UDZO $(DMG)
	@rm -rf .dmg-root
	@ls -lh $(DMG)
	@echo "DMG ready at $(DMG)"
