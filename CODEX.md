# CODEX Change Summary

## Scope
- Current workspace changes applied during the recent Codex session
- Focus: build system, dependency handling, VS Code debug flow, runtime file loading

## Build System
- `CMakePresets.json`
- Generator switched from `Ninja` to `Visual Studio 17 2022`
- Architecture unified to `x64`
- Multi-config flow enabled with `Debug`, `RelWithDebInfo`, `Release`
- `vcpkg` toolchain dependency removed from presets
- `buildPresets.configuration` added for VS multi-config builds

## Dependency Strategy
- `cmake/dependencies.cmake`
- `zlib` moved to `FetchContent`
- `ZLIB::ZLIB` target alias normalized
- `FBX SDK` auto-download kept, but now degrades gracefully
- `7-Zip` missing -> FBX exporter disabled instead of configure failure
- `vcredist_x64.exe` auto-download retained for installer workflow

## CMake Integration
- `CMakeLists.txt`
- Ninja-specific compiler bootstrap limited to Ninja generators
- embedded `CascLib` install/export rules suppressed for local build integration

## Linkage Cleanup
- `Source/Engine/CMakeLists.txt`
- `Source/App/CMakeLists.txt`
- hardcoded `ThirdParty/lib/x64/zlib.lib` linkage removed
- targets now link through `ZLIB::ZLIB`
- FBX exporter linkage made conditional

## Feature Gating
- `Source/WoW/CMakeLists.txt`
- `Source/App/Application.cpp`
- FBX exporter subdirectory build is optional
- runtime exporter registration is wrapped by `WMV_ENABLE_FBX_EXPORTER`

## Runtime File Loading
- `Source/App/GameLoader.cpp`
- `listfile.csv` loading changed to executable/app directory context
- empty listfile result now emits a warning for easier diagnosis

## CASC Support Files
- `Source/WoW/CASC/CASCFolder.cpp`
- `extraEncryptionKeys.csv` loading changed to config/app directory context
- missing file now logs a warning instead of failing silently

## Third-Party Adjustments
- `ThirdParty/casclib`
- optional skip-install mode added for embedded build usage
- reuse `ZLIB::ZLIB` target when already provided by parent project
- `ThirdParty/glad`
- local `jinja2` bootstrap added for generator execution
- Python-based glad generation no longer depends on a global `jinja2` install

## VS Code
- `.vscode/launch.json`
- `.vscode/tasks.json`
- `x64-Debug` debug launch added
- `x64-Release` debug launch added
- release launch path corrected to `bin/wowmodelviewer.exe`
- release build task targets `wowmodelviewer` executable directly
- release package task kept separate from executable build task

## Build Status
- `x64-Debug` configure: OK
- `x64-Debug` build: OK
- `x64-Release` executable build: OK
- release executable output confirmed at `bin/wowmodelviewer.exe`
- `x64-Release` package target: not fully fixed
- current package failure point: NSIS expects `bin\\*.dll`

## Known Notes
- MSVC `C4819` source encoding warnings still appear
- warnings do not currently block build completion
- FBX exporter remains disabled when `7-Zip` is unavailable
