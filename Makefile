PYTHON := python3.12
CORE_SOURCES := Sources/MiniDiabloCore/Assets.swift Sources/MiniDiabloCore/Combat.swift Sources/MiniDiabloCore/Dungeon.swift Sources/MiniDiabloCore/Items.swift Sources/MiniDiabloCore/Story.swift
CORE_SMOKE := /tmp/mini-diablo-core-smoke

.PHONY: validate validate-local validate-core validate-structure validate-ios

validate: validate-local

validate-local: validate-structure validate-core

validate-structure:
	$(PYTHON) Scripts/validate_project.py
	$(PYTHON) -m py_compile Scripts/validate_project.py Scripts/chroma_key_png.py
	plutil -lint MiniDiablo.xcodeproj/project.pbxproj MiniDiabloApp/Info.plist
	xmllint --noout MiniDiablo.xcodeproj/xcshareddata/xcschemes/MiniDiablo.xcscheme MiniDiabloApp/Resources/LaunchScreen.storyboard
	rm -rf Scripts/__pycache__

validate-core:
	swiftc $(CORE_SOURCES) Scripts/CoreSmoke/main.swift -o $(CORE_SMOKE)
	$(CORE_SMOKE)

validate-ios:
	Scripts/validate_ios_build.sh
