# cmake/dependencies.cmake
# Downloads and configures external dependencies that were previously handled
# by scripts/setup_x64_deps.ps1. Runs automatically at configure time.
# Requires: 7-Zip on PATH or at its default install location (for FBX SDK).

include_guard(GLOBAL)
include(FetchContent)
option(WMV_ENABLE_FBX_EXPORTER "Build Autodesk FBX exporter support" ON)

# ---------------------------------------------------------------------------
# Helper: find 7-Zip (needed to extract the FBX SDK NSIS installer)
# ---------------------------------------------------------------------------
function(_find_7zip out_var)
  find_program(_7z 7z PATHS "$ENV{ProgramFiles}/7-Zip" NO_CACHE)
  if(_7z)
    set(${out_var} "${_7z}" PARENT_SCOPE)
  else()
    message(FATAL_ERROR
      "7-Zip not found.  Install from https://7-zip.org or ensure 7z is on PATH.")
  endif()
endfunction()

# ---------------------------------------------------------------------------
# 1. zlib  (built from source via FetchContent)
# ---------------------------------------------------------------------------
message(STATUS "Fetching zlib 1.3.1...")
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
FetchContent_Declare(
  zlib
  URL https://github.com/madler/zlib/archive/refs/tags/v1.3.1.zip
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(zlib)

if(TARGET zlibstatic AND NOT TARGET ZLIB::ZLIB)
  add_library(ZLIB::ZLIB ALIAS zlibstatic)
elseif(TARGET zlib AND NOT TARGET ZLIB::ZLIB)
  add_library(ZLIB::ZLIB ALIAS zlib)
elseif(NOT TARGET ZLIB::ZLIB)
  message(FATAL_ERROR "Unable to determine the zlib target created by FetchContent.")
endif()

# ---------------------------------------------------------------------------
# 2. FBX SDK 2020.3.9  (download + extract at configure time)
# ---------------------------------------------------------------------------
if(WMV_ENABLE_FBX_EXPORTER)
  set(_fbx_inc_dst "${CMAKE_SOURCE_DIR}/ThirdParty/include")
  set(_fbx_lib_dst "${CMAKE_SOURCE_DIR}/ThirdParty/lib/x64")
  set(_fbx_sentinel "${_fbx_inc_dst}/fbxsdk.h")

  if(NOT EXISTS "${_fbx_sentinel}")
    find_program(_7z_exe 7z PATHS "$ENV{ProgramFiles}/7-Zip" NO_CACHE)
    if(NOT _7z_exe)
      message(WARNING "7-Zip not found. Disabling FBX exporter support.")
      set(WMV_ENABLE_FBX_EXPORTER OFF CACHE BOOL "Build Autodesk FBX exporter support" FORCE)
    else()
      message(STATUS "FBX SDK not found, downloading 2020.3.9 ...")

      set(_fbx_tmp "${CMAKE_BINARY_DIR}/_deps/fbx_download")
      file(MAKE_DIRECTORY "${_fbx_tmp}")

      set(_fbx_installer "${_fbx_tmp}/fbx202039_fbxsdk_vs2022_win.exe")
      if(NOT EXISTS "${_fbx_installer}")
        file(DOWNLOAD
          "https://damassets.autodesk.net/content/dam/autodesk/www/files/fbx202039_fbxsdk_vs2022_win.exe"
          "${_fbx_installer}"
          SHOW_PROGRESS
          STATUS _dl_status
        )
        list(GET _dl_status 0 _dl_rc)
        if(NOT _dl_rc EQUAL 0)
          list(GET _dl_status 1 _dl_msg)
          message(FATAL_ERROR "FBX SDK download failed: ${_dl_msg}")
        endif()
      endif()

      set(_fbx_extract "${_fbx_tmp}/extracted")
      if(NOT EXISTS "${_fbx_extract}")
        message(STATUS "Extracting FBX SDK ...")
        file(MAKE_DIRECTORY "${_fbx_extract}")
        execute_process(
          COMMAND "${_7z_exe}" x "${_fbx_installer}" -o${_fbx_extract} -aoa -bd
          RESULT_VARIABLE _7z_rc
          OUTPUT_QUIET
        )
        if(NOT _7z_rc EQUAL 0)
          message(FATAL_ERROR "7z extraction failed for FBX SDK installer (exit ${_7z_rc})")
        endif()
      endif()

      # Locate fbxsdk.h inside the extraction tree.
      file(GLOB_RECURSE _fbx_headers "${_fbx_extract}/*/fbxsdk.h")
      if(NOT _fbx_headers)
        # Also try flat layout (no intermediate directory).
        if(EXISTS "${_fbx_extract}/include/fbxsdk.h")
          set(_fbx_headers "${_fbx_extract}/include/fbxsdk.h")
        else()
          message(FATAL_ERROR "Could not find fbxsdk.h in extracted FBX SDK")
        endif()
      endif()
      list(GET _fbx_headers 0 _fbx_header_path)
      cmake_path(GET _fbx_header_path PARENT_PATH _fbx_inc_src)   # .../include
      cmake_path(GET _fbx_inc_src     PARENT_PATH _fbx_root)      # .../

      # Copy headers.
      file(MAKE_DIRECTORY "${_fbx_inc_dst}")
      file(COPY "${_fbx_inc_src}/fbxsdk.h" DESTINATION "${_fbx_inc_dst}")
      file(COPY "${_fbx_inc_src}/fbxsdk"   DESTINATION "${_fbx_inc_dst}")

      # Locate x64/release libs.
      file(GLOB_RECURSE _fbx_libs "${_fbx_root}/*/x64/release/libfbxsdk.lib")
      if(NOT _fbx_libs)
        message(FATAL_ERROR "Could not find libfbxsdk.lib under x64/release in extracted FBX SDK")
      endif()
      list(GET _fbx_libs 0 _fbx_lib_path)
      cmake_path(GET _fbx_lib_path PARENT_PATH _fbx_lib_src)

      file(MAKE_DIRECTORY "${_fbx_lib_dst}")
      file(COPY "${_fbx_lib_src}/libfbxsdk.lib" DESTINATION "${_fbx_lib_dst}")
      file(COPY "${_fbx_lib_src}/libfbxsdk.dll" DESTINATION "${_fbx_lib_dst}")
      message(STATUS "FBX SDK 2020.3.9 installed.")
    endif()
  else()
    message(STATUS "FBX SDK found at ${_fbx_sentinel}")
  endif()
else()
  message(STATUS "FBX exporter support disabled.")
endif()

# ---------------------------------------------------------------------------
# 3. vcredist_x64.exe  (for the NSIS installer)
# ---------------------------------------------------------------------------
set(_vcredist_dst "${CMAKE_SOURCE_DIR}/bin_support/vcredist_x64.exe")
if(NOT EXISTS "${_vcredist_dst}")
  message(STATUS "Downloading vcredist_x64.exe ...")
  file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/bin_support")
  file(DOWNLOAD
    "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    "${_vcredist_dst}"
    SHOW_PROGRESS
    STATUS _vcr_status
  )
  list(GET _vcr_status 0 _vcr_rc)
  if(NOT _vcr_rc EQUAL 0)
    list(GET _vcr_status 1 _vcr_msg)
    message(WARNING "Failed to download vcredist_x64.exe: ${_vcr_msg}")
  endif()
else()
  message(STATUS "vcredist_x64.exe already present.")
endif()
