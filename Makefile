SWIFT := /Library/Developer/CommandLineTools/usr/bin/swift
ENV := DEVELOPER_DIR=/Library/Developer/CommandLineTools
BINARY := .build/debug/PullTimer
BINARY_RELEASE := .build/release/PullTimer
APP_DIR := PullTimer.app/Contents
MACOS_DIR := $(APP_DIR)/MacOS
INFO_PLIST := Info.plist

.PHONY: all build bundle run clean release

all: bundle

build:
	$(ENV) $(SWIFT) build

bundle: build
	@mkdir -p $(MACOS_DIR)
	@cp $(BINARY) $(MACOS_DIR)/PullTimer
	@cp $(INFO_PLIST) $(APP_DIR)/Info.plist
	@codesign --force --deep --sign - --identifier "com.pulltimer.app" PullTimer.app
	@echo "App bundle created and signed at PullTimer.app"

run: bundle
	@pkill -x PullTimer 2>/dev/null || true
	@sleep 0.3
	@open PullTimer.app

clean:
	@rm -rf .build PullTimer.app

release:
	$(ENV) $(SWIFT) build -c release
	@mkdir -p $(MACOS_DIR)
	@cp $(BINARY_RELEASE) $(MACOS_DIR)/PullTimer
	@cp $(INFO_PLIST) $(APP_DIR)/Info.plist
	@echo "Release bundle at PullTimer.app"
