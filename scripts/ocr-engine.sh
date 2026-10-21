#!/usr/bin/env bash
# Builds the OCR engine the app downloads on demand (issue #593): one
# shared library holding Tesseract and a static Leptonica, with no image
# codecs (the app hands the pixels over raw), no legacy engine (the
# tessdata_fast/best models are LSTM only), no OpenMP, no network, no
# training tools.
#
#   scripts/ocr-engine.sh <target> <out dir>
#   targets: linux-x64 | android-arm64-v8a | android-x86_64 | windows-x64
#            | macos-universal (macos-arm64 and macos-x86_64, joined)
#
# Android needs ANDROID_NDK_HOME; Windows runs under Git Bash with MSVC;
# the Mac needs Xcode, cmake and ninja.
# The library lands in <out dir> as niman-ocr-<target>.<so|dll|dylib>.
# The Mac's is bundled in the app rather than downloaded: under the
# hardened runtime the app loads only a library signed with its own team
# (docs/records/apple-platforms.md).
set -euo pipefail

TESSERACT_VERSION=5.5.3
LEPTONICA_VERSION=1.87.0
CPU_FEATURES_VERSION=v0.11.0

target="${1:?target}"
out="$(mkdir -p "${2:?out dir}" && cd "$2" && pwd)"

# Tesseract picks its SIMD sources (NEON or AVX) for a build's one
# processor: a universal CMake build linked NEON calls into its x86_64
# half. Each half is built on its own, then the two are joined.
if [ "$target" = macos-universal ]; then
  for arch in arm64 x86_64; do
    "$0" "macos-$arch" "$out/.macos-$arch" >/dev/null || exit 1
  done
  dest="$out/niman-ocr-macos-universal.dylib"
  lipo -create "$out/.macos-arm64/niman-ocr-macos-arm64.dylib" \
    "$out/.macos-x86_64/niman-ocr-macos-x86_64.dylib" -output "$dest"
  rm -rf "$out/licenses"
  mv "$out/.macos-arm64/licenses" "$out/licenses"
  rm -rf "$out/.macos-arm64" "$out/.macos-x86_64"
  echo "$dest $(wc -c <"$dest") bytes"
  exit 0
fi
work="${OCR_ENGINE_WORK:-${TMPDIR:-/tmp}/niman/ocr-engine}/$target"
mkdir -p "$work"
cd "$work"

# A step's output only when it fails.
run() { "$@" >"$work/step.log" 2>&1 || { tail -40 "$work/step.log" >&2; exit 1; }; }

fetch() { # <repo> <tag> <dir>
  [ -d "$3" ] || git clone -q --depth 1 --branch "$2" "https://github.com/$1.git" "$3"
}
fetch DanBloomberg/leptonica "$LEPTONICA_VERSION" leptonica-src
fetch tesseract-ocr/tesseract "$TESSERACT_VERSION" tesseract-src

# Only the C API (`Tess*`) is exported, so the linker drops the rest of
# what the app never calls.
printf '{ global: Tess*; local: *; };\n' >"$work/exports.map"
gc_flags="-ffunction-sections -fdata-sections"
elf_link="-Wl,--gc-sections -Wl,--version-script=$work/exports.map -Wl,--exclude-libs,ALL"

common=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  -DCMAKE_INSTALL_PREFIX="$work/prefix" -DCMAKE_PREFIX_PATH="$work/prefix"
  -DCMAKE_FIND_ROOT_PATH="$work/prefix" -DSW_BUILD=OFF)
# Leptonica's warnings go to stderr, which is the app's own.
lepton_flags="$gc_flags -DNO_CONSOLE_IO"
generator=(-G Ninja)
strip_cmd=(strip --strip-unneeded)
lib_glob='libtesseract.so*'
ext=so
case "$target" in
  linux-x64)
    common+=("-DCMAKE_C_FLAGS=$gc_flags" "-DCMAKE_CXX_FLAGS=$gc_flags"
      "-DCMAKE_SHARED_LINKER_FLAGS=-static-libstdc++ -static-libgcc $elf_link")
    ;;
  android-arm64-v8a | android-x86_64)
    ndk="${ANDROID_NDK_HOME:?ANDROID_NDK_HOME}"
    common+=(-DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake"
      -DANDROID_ABI="${target#android-}" -DANDROID_PLATFORM=android-34
      -DANDROID_STL=c++_static -DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON
      "-DCMAKE_C_FLAGS=$gc_flags" "-DCMAKE_CXX_FLAGS=$gc_flags"
      "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384 $elf_link")
    strip_cmd=("$(ls -d "$ndk"/toolchains/llvm/prebuilt/*/bin | head -1)/llvm-strip" --strip-unneeded)
    ;;
  macos-arm64 | macos-x86_64)
    # One Mac architecture, linked the Mach-O way: ld64 dead-strips where
    # ELF garbage-collects sections, and an exported symbols list does what
    # the version script does. The processor is named, as a cross build's
    # is, so Tesseract picks that one's SIMD sources. CMake 4 refuses
    # Leptonica's old minimum version unless told which policies to take.
    printf '_Tess*\n' >"$work/exports.txt"
    common+=("-DCMAKE_OSX_ARCHITECTURES=${target#macos-}"
      -DCMAKE_SYSTEM_NAME=Darwin "-DCMAKE_SYSTEM_PROCESSOR=${target#macos-}"
      -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
      "-DCMAKE_C_FLAGS=$gc_flags" "-DCMAKE_CXX_FLAGS=$gc_flags"
      "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-dead_strip -Wl,-exported_symbols_list,$work/exports.txt")
    strip_cmd=(strip -x)
    lib_glob='libtesseract*.dylib'
    ext=dylib
    ;;
  windows-x64)
    generator=(-G "Visual Studio 17 2022" -A x64)
    # Static CRT in both libraries; Leptonica's old cmake_minimum_required
    # ignores the runtime setting unless the policy is forced.
    common+=(-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded
      -DCMAKE_POLICY_DEFAULT_CMP0091=NEW)
    lepton_flags=-DNO_CONSOLE_IO
    strip_cmd=(true)
    lib_glob='tesseract*.dll'
    ext=dll
    ;;
  *) echo "unknown target: $target" >&2; exit 2 ;;
esac

if [[ "$target" == android-* ]]; then
  # Tesseract's NEON detection on Android links cpu_features' ndk_compat.
  fetch google/cpu_features "$CPU_FEATURES_VERSION" cpu-features-src
  run cmake -S cpu-features-src -B cpu-features-build "${generator[@]}" "${common[@]}" \
    -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DBUILD_EXECUTABLE=OFF
  run cmake --build cpu-features-build --target install
fi

run cmake -S leptonica-src -B leptonica-build "${generator[@]}" "${common[@]}" \
  -DBUILD_SHARED_LIBS=OFF -DBUILD_PROG=OFF "-DCMAKE_C_FLAGS=$lepton_flags" \
  -DENABLE_ZLIB=OFF -DENABLE_PNG=OFF -DENABLE_GIF=OFF -DENABLE_JPEG=OFF \
  -DENABLE_TIFF=OFF -DENABLE_WEBP=OFF -DENABLE_OPENJPEG=OFF
run cmake --build leptonica-build --config Release --target install

# LEPT_TIFF_RESULT answers the TIFF probe a cross build cannot run: none.
run cmake -S tesseract-src -B tesseract-build "${generator[@]}" "${common[@]}" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TRAINING_TOOLS=OFF -DBUILD_TESTS=OFF \
  -DDISABLE_ARCHIVE=ON -DDISABLE_CURL=ON -DDISABLE_TIFF=ON \
  -DGRAPHICS_DISABLED=ON -DOPENMP_BUILD=OFF -DDISABLED_LEGACY_ENGINE=ON \
  -DENABLE_LTO=ON -DINSTALL_CONFIGS=OFF \
  -DLEPT_TIFF_RESULT=1 \
  -DLeptonica_DIR="$work/prefix/lib/cmake/leptonica"
run cmake --build tesseract-build --config Release --target libtesseract

# The real file, not a soname symlink.
lib="$(find tesseract-build -name "$lib_glob" -type f | head -1)"
dest="$out/niman-ocr-$target.$ext"
cp "$lib" "$dest"
"${strip_cmd[@]}" "$dest"
# The name the app's bundle loads it by, wherever the build put it.
if [ "$ext" = dylib ]; then install_name_tool -id @rpath/libniman_ocr.dylib "$dest"; fi
mkdir -p "$out/licenses"
cp tesseract-src/LICENSE "$out/licenses/tesseract.txt"
cp leptonica-src/leptonica-license.txt "$out/licenses/leptonica.txt"
echo "$dest $(wc -c <"$dest") bytes"
