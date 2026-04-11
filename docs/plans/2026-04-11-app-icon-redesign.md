# App Icon Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create and install a new Jupiter app icon in the approved stacked-Polaroid reference style.

**Architecture:** Generate the icon programmatically as a deterministic high-resolution bitmap so the visual can be iterated quickly and dropped directly into the existing Xcode asset catalog. Keep the asset pipeline simple: produce candidate PNGs, select one, and wire it into `AppIcon.appiconset`.

**Tech Stack:** Python 3 bitmap drawing, Xcode asset catalog

---

### Task 1: Create deterministic icon generator

**Files:**
- Create: `/Users/rich/Projects/Jupiter/scripts/generate_app_icon.py`

**Step 1: Write the generator**

Implement a script that renders:
- cream rounded-square base
- warm-red circular backing
- two offset Polaroid cards
- minimal photo content
- soft shadow and small highlight details

**Step 2: Run generator**

Run: `python3 /Users/rich/Projects/Jupiter/scripts/generate_app_icon.py`

Expected: candidate PNG files written under `/Users/rich/Projects/Jupiter/tmp/app-icon/`

### Task 2: Install chosen icon

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `/Users/rich/Projects/Jupiter/Jupiter/Assets.xcassets/AppIcon.appiconset/app-icon-polaroid-v1.png`

**Step 1: Copy selected output**

Place the chosen 1024x1024 PNG into the app icon asset set with a stable filename.

**Step 2: Update asset metadata if needed**

Ensure the universal iOS 1024 entry points to the new file.

### Task 3: Verify build compatibility

**Files:**
- None

**Step 1: Build for testing**

Run: `xcodebuild build-for-testing -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,id=B3B28A6B-B593-419C-A688-921A025A7BF8' -parallel-testing-enabled NO`

Expected: `TEST BUILD SUCCEEDED`
