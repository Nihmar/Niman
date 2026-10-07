#!/usr/bin/env bash
# Builds the OCR engine the app downloads on demand (issue #593): one
# shared library holding Tesseract and a static Leptonica, with no image
# codecs (the app hands the pixels over raw), no legacy engine (the
# tessdata_fast/best models are LSTM only), no OpenMP, no network, no
# training tools.
#
#   scripts/ocr-engine.sh <target> <out dir>
#   targets: linux-x64 | android-arm64-v8a | android-x86_64 | windows-x64
#
# Android needs ANDROID_NDK_HOME; Windows runs under Git Bash with MSVC.
# The library lands in <out dir> as niman-ocr-<target>.<so|dll>.
set -euo pipefail

TESSERACT_VERSION=5.5.3
LEPTONICA_VERSION=1.87.0
CPU_FEATURES_VERSION=v0.11.0

target="${1:?target}"
out="$(mkdir -p "${2:?out dir}" && cd "$2" && pwd)"
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
      -DANDROID_ABI="${target#android-}" -DANDROID_PLATFORM=android-35
      -DANDROID_STL=c++_static -DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON
      "-DCMAKE_C_FLAGS=$gc_flags" "-DCMAKE_CXX_FLAGS=$gc_flags"
      "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384 $elf_link")
    strip_cmd=("$(ls -d "$ndk"/toolchains/llvm/prebuilt/*/bin | head -1)/llvm-strip" --strip-unneeded)
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
mkdir -p "$out/licenses"
cp tesseract-src/LICENSE "$out/licenses/tesseract.txt"
cp leptonica-src/leptonica-license.txt "$out/licenses/leptonica.txt"
echo "$dest $(wc -c <"$dest") bytes"
