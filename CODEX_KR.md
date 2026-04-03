# CODEX 변경 요약

## 범위
- 최근 Codex 작업 세션에서 현재 작업 트리에 반영한 변경
- 초점: 빌드 시스템, 의존성 처리, VS Code 디버그 흐름, 런타임 파일 로딩

## 빌드 시스템
- `CMakePresets.json`
- 제너레이터를 `Ninja` 에서 `Visual Studio 17 2022` 로 변경
- 아키텍처를 `x64` 로 통일
- `Debug`, `RelWithDebInfo`, `Release` 멀티컨피그 흐름 적용
- 프리셋에서 `vcpkg` 툴체인 의존 제거
- VS 멀티컨피그 빌드를 위해 `buildPresets.configuration` 추가

## 의존성 전략
- `cmake/dependencies.cmake`
- `zlib` 를 `FetchContent` 기반으로 전환
- `ZLIB::ZLIB` 타깃 별칭 정리
- `FBX SDK` 자동 다운로드 흐름은 유지
- `7-Zip` 미설치 시 configure 실패 대신 FBX exporter 비활성화
- 설치 패키지용 `vcredist_x64.exe` 자동 다운로드 유지

## CMake 통합
- `CMakeLists.txt`
- Ninja 전용 컴파일러 부트스트랩을 Ninja 제너레이터에서만 동작하게 제한
- 내장 `CascLib` 를 부모 프로젝트에 통합할 때 install/export 규칙 생략 가능하게 조정

## 링크 정리
- `Source/Engine/CMakeLists.txt`
- `Source/App/CMakeLists.txt`
- 하드코딩된 `ThirdParty/lib/x64/zlib.lib` 링크 제거
- `ZLIB::ZLIB` 기반 링크로 통일
- FBX exporter 링크를 조건부로 변경

## 기능 게이팅
- `Source/WoW/CMakeLists.txt`
- `Source/App/Application.cpp`
- FBX exporter 서브디렉터리 빌드를 선택적으로 전환
- 런타임 exporter 등록을 `WMV_ENABLE_FBX_EXPORTER` 로 감쌈

## 런타임 파일 로딩
- `Source/App/GameLoader.cpp`
- `listfile.csv` 로딩 기준을 실행 파일/앱 디렉터리 기준으로 변경
- listfile 결과가 비어 있을 때 경고 로그 추가

## CASC 보조 파일
- `Source/WoW/CASC/CASCFolder.cpp`
- `extraEncryptionKeys.csv` 로딩 기준을 config/app 디렉터리 기준으로 변경
- 파일이 없을 때 조용히 실패하지 않고 경고 로그 출력

## 서드파티 보정
- `ThirdParty/casclib`
- 내장 빌드용 skip-install 모드 추가
- 부모 프로젝트가 제공한 `ZLIB::ZLIB` 타깃 재사용
- `ThirdParty/glad`
- 로컬 `jinja2` 부트스트랩 추가
- 시스템 전역 `jinja2` 없이도 glad 생성 가능하게 조정

## VS Code
- `.vscode/launch.json`
- `.vscode/tasks.json`
- `x64-Debug` 디버그 런치 추가
- `x64-Release` 디버그 런치 추가
- 릴리즈 런치 경로를 `bin/wowmodelviewer.exe` 로 수정
- 릴리즈 빌드 task 는 실행 파일 `wowmodelviewer` 만 직접 빌드하도록 조정
- 릴리즈 패키징 task 는 실행 파일 빌드와 분리 유지

## 빌드 상태
- `x64-Debug` configure: 정상
- `x64-Debug` build: 정상
- `x64-Release` 실행 파일 build: 정상
- 릴리즈 실행 파일 출력 확인 위치: `bin/wowmodelviewer.exe`
- `x64-Release` 패키지 타깃: 아직 완전 해결 전
- 현재 패키징 실패 지점: NSIS 가 `bin\\*.dll` 을 기대함

## 참고 사항
- MSVC `C4819` 소스 인코딩 경고는 아직 존재
- 현재 경고는 빌드 완료를 막지는 않음
- `7-Zip` 이 없으면 FBX exporter 는 비활성 상태로 유지
