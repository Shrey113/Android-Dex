#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🚀 Android Dex — Linux Launcher
#  Designed by: Shrey113
#  GitHub: https://github.com/Shrey113/Android-Dex
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Colours ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
CYN='\033[0;36m'
BLD='\033[1m'
NC='\033[0m'

ok()    { echo -e "${GRN}  [OK]${NC}   $*"; }
warn()  { echo -e "${YLW}  [WARN]${NC} $*"; }
err()   { echo -e "${RED}  [MISS]${NC} $*"; }
info()  { echo -e "${CYN}  [INFO]${NC} $*"; }
title() { echo -e "\n${BLD}$*${NC}"; }

# ── INTRO ──────────────────────────────────────────────────────────────────
echo -e "\n${CYN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BLD}Android Dex — Adaptive Universal Linux Launcher${NC}"
echo -e "  ${GRN}Developed by: Shrey113${NC}"
echo -e "  ${YLW}https://github.com/Shrey113/Android-Dex${NC}"
echo -e "  ─────────────────────────────────────────────────────────────────────"
echo -e "  Auto-resolves system dependencies and provides an adaptive"
echo -e "  rendering path for ultimate cross-distribution compatibility."
echo -e "${CYN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# ── App directory ─────────────────────────────────────────────────────────
HERE="$(dirname "$(readlink -f "$0")")"

export LD_LIBRARY_PATH="$HERE/lib:/usr/lib64:/usr/lib"

# ── Parse --debugging flag ────────────────────────────────────────────────
DEBUG_MODE=0
PASS_ARGS=()
for _arg in "$@"; do
    if [ "$_arg" == "--debugging" ]; then
        DEBUG_MODE=1
    else
        PASS_ARGS+=("$_arg")
    fi
done

if [ $DEBUG_MODE -eq 1 ]; then
    PASS_ARGS+=("--debugging")
    LOG_FILE="$HERE/android_dex_log.txt"
    echo -e "\n${CYN}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYN}│${NC}  ${BLD}🔍 DEBUG MODE ENABLED${NC}                                      ${CYN}│${NC}"
    echo -e "${CYN}│${NC}  All logs will be saved to:                                  ${CYN}│${NC}"
    echo -e "${CYN}│${NC}  ${YLW}$LOG_FILE${NC}"
    echo -e "${CYN}└──────────────────────────────────────────────────────────────┘${NC}\n"
fi


# FORCE X11 (For stability across Wayland/X11 distros)
export EGL_PLATFORM=x11
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb

SEARCH_PATHS=("/usr/lib/x86_64-linux-gnu/dri" "/usr/lib64/dri" "/usr/lib/dri" "/usr/lib32/dri")
DRIVERS_ENV=""
for p in "${SEARCH_PATHS[@]}"; do
    if [ -d "$p" ]; then
        DRIVERS_ENV="${DRIVERS_ENV}${DRIVERS_ENV:+:}$p"
    fi
done
export LIBGL_DRIVERS_PATH="$DRIVERS_ENV"

cd "$HERE"

DISTRO="unknown"
[ -f /etc/fedora-release ]    && DISTRO="fedora"
[ -f /etc/arch-release ]      && DISTRO="arch"
[ -f /etc/debian_version ]    && DISTRO="debian"
grep -qi ubuntu /etc/os-release 2>/dev/null && DISTRO="ubuntu"
[ -f /etc/opensuse-release ] || [ -f /etc/SUSE-brand ] && DISTRO="opensuse"

# ── Package installer ─────────────────────────────────────────────────────
do_install() {
    case $DISTRO in
        fedora)         sudo dnf install -y $1 ;;
        ubuntu|debian)  sudo apt-get install -y $2 ;;
        arch)           sudo pacman -S --noconfirm $3 ;;
        opensuse)       sudo zypper install -y $4 ;;
        *) echo "  Unknown distro — install manually: $1 / $2 / $3"; return 1 ;;
    esac
}

# ── Y/N prompt ────────────────────────────────────────────────────────────
ask_yn() {
    echo -ne "${BLD}  $1${NC} [y/N]: "
    read -r _ans
    case "$_ans" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# ── Library checker ───────────────────────────────────────────────────────
has_lib() {
    if [ -d "$HERE/lib" ]; then
        if ls "$HERE/lib"/$1* >/dev/null 2>&1; then
            return 0
        fi
    fi

    ldconfig -p 2>/dev/null | grep -q "$1" && return 0
    for _d in /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/local/lib; do
        ls "$_d"/$1* >/dev/null 2>&1 && return 0
    done
    return 1
}

echo -e "  ${CYN}Android Dex for Linux by Shrey113${NC}"
echo    "  ─────────────────────────────────────────────────────"

MISSING=0
SETUP_UDEV=0

# ── COLLECT MISSING PACKAGES (AUTO RESOLVER SYSTEM) ───────────────────────
declare -A PKG_MAP_FEDORA
declare -A PKG_MAP_UBUNTU
declare -A PKG_MAP_ARCH
declare -A PKG_MAP_OPENSUSE

# UI & Frameworks
PKG_MAP_FEDORA["libgtk-3.so.0"]="gtk3"
PKG_MAP_UBUNTU["libgtk-3.so.0"]="libgtk-3-0"
PKG_MAP_ARCH["libgtk-3.so.0"]="gtk3"
PKG_MAP_OPENSUSE["libgtk-3.so.0"]="libgtk-3-0"

PKG_MAP_FEDORA["libSDL2-2.0.so.0"]="SDL2"
PKG_MAP_UBUNTU["libSDL2-2.0.so.0"]="libsdl2-2.0-0"
PKG_MAP_ARCH["libSDL2-2.0.so.0"]="sdl2"
PKG_MAP_OPENSUSE["libSDL2-2.0.so.0"]="libSDL2-2_0-0"

# X11 & Display
PKG_MAP_FEDORA["libXss.so.1"]="libXScrnSaver"
PKG_MAP_UBUNTU["libXss.so.1"]="libxss1"
PKG_MAP_ARCH["libXss.so.1"]="libxss"
PKG_MAP_OPENSUSE["libXss.so.1"]="libXss1"

PKG_MAP_FEDORA["libXrandr.so.2"]="libXrandr"
PKG_MAP_UBUNTU["libXrandr.so.2"]="libxrandr2"
PKG_MAP_ARCH["libXrandr.so.2"]="libxrandr"
PKG_MAP_OPENSUSE["libXrandr.so.2"]="libXrandr2"

# Wayland decor
PKG_MAP_FEDORA["libdecor-0.so.0"]="libdecor"
PKG_MAP_UBUNTU["libdecor-0.so.0"]="libdecor-0-0"
PKG_MAP_ARCH["libdecor-0.so.0"]="libdecor"
PKG_MAP_OPENSUSE["libdecor-0.so.0"]="libdecor-0-0"

# Media (FFmpeg)
PKG_MAP_FEDORA["libavcodec.so.58"]="ffmpeg-libs"
PKG_MAP_UBUNTU["libavcodec.so.58"]="libavcodec-extra"
PKG_MAP_ARCH["libavcodec.so.58"]="ffmpeg"
PKG_MAP_OPENSUSE["libavcodec.so.58"]="libavcodec6x"

PKG_MAP_FEDORA["libavcodec.so.59"]="ffmpeg-libs"
PKG_MAP_UBUNTU["libavcodec.so.59"]="libavcodec-extra"
PKG_MAP_ARCH["libavcodec.so.59"]="ffmpeg"
PKG_MAP_OPENSUSE["libavcodec.so.59"]="libavcodec6x"

# Codec libs required by bundled ffmpeg builds
PKG_MAP_FEDORA["libjxl.so.0.7"]="libjxl"
PKG_MAP_UBUNTU["libjxl.so.0.7"]="libjxl0.7"
PKG_MAP_ARCH["libjxl.so.0.7"]="libjxl"
PKG_MAP_OPENSUSE["libjxl.so.0.7"]="libjxl0_7"

PKG_MAP_FEDORA["libjxl_threads.so.0.7"]="libjxl"
PKG_MAP_UBUNTU["libjxl_threads.so.0.7"]="libjxl0.7"
PKG_MAP_ARCH["libjxl_threads.so.0.7"]="libjxl"
PKG_MAP_OPENSUSE["libjxl_threads.so.0.7"]="libjxl0_7"

PKG_MAP_FEDORA["librav1e.so.0"]="rav1e-libs"
PKG_MAP_UBUNTU["librav1e.so.0"]="librav1e0"
PKG_MAP_ARCH["librav1e.so.0"]="rav1e"
PKG_MAP_OPENSUSE["librav1e.so.0"]="librav1e0"

PKG_MAP_FEDORA["libSvtAv1Enc.so.1"]="svt-av1-libs"
PKG_MAP_UBUNTU["libSvtAv1Enc.so.1"]="libsvtav1enc1"
PKG_MAP_ARCH["libSvtAv1Enc.so.1"]="svt-av1"
PKG_MAP_OPENSUSE["libSvtAv1Enc.so.1"]="libSvtAv1Enc1"

PKG_MAP_FEDORA["librist.so.4"]="librist"
PKG_MAP_UBUNTU["librist.so.4"]="librist4"
PKG_MAP_ARCH["librist.so.4"]="librist"
PKG_MAP_OPENSUSE["librist.so.4"]="librist4"

# EGL / GL
PKG_MAP_FEDORA["libEGL.so.1"]="mesa-libEGL mesa-libGL mesa-dri-drivers mesa-libglapi mesa-libgbm"
PKG_MAP_UBUNTU["libEGL.so.1"]="libegl1 libgl1-mesa-dri"
PKG_MAP_ARCH["libEGL.so.1"]="mesa"
PKG_MAP_OPENSUSE["libEGL.so.1"]="Mesa-libEGL1 Mesa-dri"

PKG_MAP_FEDORA["libepoxy.so.0"]="libepoxy"
PKG_MAP_UBUNTU["libepoxy.so.0"]="libepoxy0"
PKG_MAP_ARCH["libepoxy.so.0"]="libepoxy"
PKG_MAP_OPENSUSE["libepoxy.so.0"]="libepoxy0"

PKG_MAP_FEDORA["libusb-1.0.so.0"]="libusb1"
PKG_MAP_UBUNTU["libusb-1.0.so.0"]="libusb-1.0-0"
PKG_MAP_ARCH["libusb-1.0.so.0"]="libusb"
PKG_MAP_OPENSUSE["libusb-1.0.so.0"]="libusb-1_0-0"

# Legacy Network Services (Legacy libnsl)
PKG_MAP_FEDORA["libnsl.so.1"]="libnsl"
PKG_MAP_UBUNTU["libnsl.so.1"]="libnsl1"
PKG_MAP_ARCH["libnsl.so.1"]="libnsl"
PKG_MAP_OPENSUSE["libnsl.so.1"]="libnsl1"

# Audio Decoders (Conflict-prone, avoid bundling)
PKG_MAP_FEDORA["libmpg123.so.0"]="mpg123-libs"
PKG_MAP_UBUNTU["libmpg123.so.0"]="libmpg123-0"
PKG_MAP_ARCH["libmpg123.so.0"]="mpg123"
PKG_MAP_OPENSUSE["libmpg123.so.0"]="libmpg123-0"

# Tray / Indicator (Runtime dlopen)
PKG_MAP_FEDORA["libayatana-appindicator3.so.1"]="libayatana-appindicator-gtk3"
PKG_MAP_UBUNTU["libayatana-appindicator3.so.1"]="libayatana-appindicator3-1"
PKG_MAP_ARCH["libayatana-appindicator3.so.1"]="libayatana-appindicator-gtk3"
PKG_MAP_OPENSUSE["libayatana-appindicator3.so.1"]="libayatana-appindicator3-1"

AUTO_INSTALL_PKGS=()

# ── Arch rolling compatibility shim for SONAME bumps ─────────────────────
ensure_compat_link() {
    local required="$1"
    shift

    if [ -e "$HERE/lib/$required" ] || has_lib "$required"; then
        return 0
    fi

    for candidate in "$@"; do
        if [ -e "$candidate" ]; then
            ln -sfn "$candidate" "$HERE/lib/$required"
            ok "Created compatibility link: $required -> $(basename "$candidate")"
            return 0
        fi
    done
    return 1
}

if [ "$DISTRO" = "arch" ]; then
    ensure_compat_link "libjxl.so.0.7" \
        /usr/lib/libjxl.so.0.12 /usr/lib/libjxl.so.0.11 /usr/lib/libjxl.so.0.10 /usr/lib/libjxl.so
    ensure_compat_link "libjxl_threads.so.0.7" \
        /usr/lib/libjxl_threads.so.0.12 /usr/lib/libjxl_threads.so.0.11 /usr/lib/libjxl_threads.so.0.10 /usr/lib/libjxl_threads.so
    ensure_compat_link "librav1e.so.0" \
        /usr/lib/librav1e.so.0.8 /usr/lib/librav1e.so.0.7 /usr/lib/librav1e.so
    ensure_compat_link "libSvtAv1Enc.so.1" \
        /usr/lib/libSvtAv1Enc.so.4 /usr/lib/libSvtAv1Enc.so.3 /usr/lib/libSvtAv1Enc.so.2 /usr/lib/libSvtAv1Enc.so
fi

# ── 1. AUTO RESOLVE FROM LDD ─────────────────────────────
APP_BINARY="./android_dex_win"
if [ -f "$APP_BINARY" ]; then
    MISSING_LDD=$(ldd "$APP_BINARY" 2>/dev/null | grep "not found")
    
    if [ -f "./Build_copy/adb" ]; then
        chmod +x "./Build_copy/adb"
        MISSING_ADB=$(ldd "./Build_copy/adb" 2>/dev/null | grep "not found")
        if [ -n "$MISSING_ADB" ]; then
            if [ -n "$MISSING_LDD" ]; then MISSING_LDD="${MISSING_LDD}"$'\n'"$MISSING_ADB"; else MISSING_LDD="$MISSING_ADB"; fi
        fi
    fi

    if [ -n "$MISSING_LDD" ]; then
        warn "Auto-detected missing binary dependencies:"
        echo "$MISSING_LDD" | sed 's/^/      /'

        while read -r line; do
            lib=$(echo "$line" | awk '{print $1}')
            pkg=""
            case $DISTRO in
                fedora)   pkg="${PKG_MAP_FEDORA[$lib]}" ;;
                ubuntu|debian) pkg="${PKG_MAP_UBUNTU[$lib]}" ;;
                arch)     pkg="${PKG_MAP_ARCH[$lib]}" ;;
                opensuse) pkg="${PKG_MAP_OPENSUSE[$lib]}" ;;
            esac

            if [ -n "$pkg" ]; then
                AUTO_INSTALL_PKGS+=($pkg)
            else
                warn "No package mapping for: $lib (Manual install may be needed)"
            fi
        done <<< "$MISSING_LDD"
    fi
fi

# ── 2. CHECK RUNTIME-ONLY LIBS (NOT IN LDD) ──────────────
if ! has_lib "libayatana-appindicator3.so" && ! has_lib "libappindicator3.so"; then
    case $DISTRO in
        fedora)   AUTO_INSTALL_PKGS+=("${PKG_MAP_FEDORA[libayatana-appindicator3.so.1]}") ;;
        ubuntu|debian) AUTO_INSTALL_PKGS+=("${PKG_MAP_UBUNTU[libayatana-appindicator3.so.1]}") ;;
        arch)     AUTO_INSTALL_PKGS+=("${PKG_MAP_ARCH[libayatana-appindicator3.so.1]}") ;;
        opensuse) AUTO_INSTALL_PKGS+=("${PKG_MAP_OPENSUSE[libayatana-appindicator3.so.1]}") ;;
    esac
fi

# Flutter needs zenity or kdialog for file picker dialogs on Linux
if ! command -v zenity >/dev/null 2>&1 && ! command -v kdialog >/dev/null 2>&1; then
    case $DISTRO in
        fedora|ubuntu|debian|arch|opensuse) AUTO_INSTALL_PKGS+=("zenity") ;;
    esac
fi

# ── 3. CHECK MESA DRI DRIVERS (VM FALLBACK) ──────────────
DRI_OK=0
for _f in /usr/lib/dri/*.so /usr/lib/*/dri/*.so /usr/lib64/dri/*.so; do
    if [[ "$_f" == *"swrast_dri.so"* || "$_f" == *"virtio_gpu_dri.so"* ]]; then
        [ -f "$_f" ] && DRI_OK=1 && break
    fi
done
if [ $DRI_OK -eq 0 ]; then
    case $DISTRO in
        fedora)   AUTO_INSTALL_PKGS+=("mesa-dri-drivers mesa-libgbm mesa-libglapi") ;;
        ubuntu|debian) AUTO_INSTALL_PKGS+=("libgl1-mesa-dri") ;;
        arch)     AUTO_INSTALL_PKGS+=("mesa") ;;
        opensuse) AUTO_INSTALL_PKGS+=("Mesa-dri") ;;
    esac
fi

# ── 4. SUMMARY & INSTALLATION ────────────────────────────
UNIQUE_PKGS=($(printf "%s\n" "${AUTO_INSTALL_PKGS[@]}" | sort -u))

if [ ${#UNIQUE_PKGS[@]} -eq 0 ]; then
    ok "All binary dependencies already installed"
else
    echo
    echo -e "${YLW}Missing dependencies detected:${NC}"
    for p in "${UNIQUE_PKGS[@]}"; do
        echo "  - $p"
    done
    echo

    INSTALL_ALL=0
    if [ "$1" == "--auto" ]; then
        INSTALL_ALL=1
        info "Auto-install mode enabled"
    else
        ask_yn "Install ALL auto-detected dependencies now?" && INSTALL_ALL=1
    fi

    if [ "$INSTALL_ALL" -eq 1 ]; then
        title "Updating Package Index & Installing Dependencies"
        case $DISTRO in
            fedora)         sudo dnf install -y "${UNIQUE_PKGS[@]}" ;;
            ubuntu|debian)  sudo apt-get update && sudo apt-get install -y "${UNIQUE_PKGS[@]}" ;;
            arch)           sudo pacman -Sy --noconfirm "${UNIQUE_PKGS[@]}" ;;
            opensuse)       sudo zypper install -y "${UNIQUE_PKGS[@]}" ;;
            *) echo -e "${RED}Unknown distro — install manually: ${UNIQUE_PKGS[*]}${NC}"; exit 1 ;;
        esac
        ok "Installation completed. Verifying..."
        sudo ldconfig 2>/dev/null
    else
        err "User skipped auto-install — app may fail to launch"
        exit 1
    fi
fi

# ── CHECK 6: udev rules ───────────────────────────────────────────────────
if [ -f /etc/udev/rules.d/51-android.rules ] || \
   [ -f /lib/udev/rules.d/51-android.rules ] || \
   [ -f /usr/lib/udev/rules.d/51-android.rules ]; then
    ok "Android udev rules  (USB device access)"
else
    warn "Android udev rules not found — cannot connect Android devices via USB"
    if ask_yn "Set up Android USB rules now? (requires sudo)"; then
        echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="*", MODE="0666", GROUP="plugdev"' \
            | sudo tee /etc/udev/rules.d/51-android.rules > /dev/null && \
        sudo udevadm control --reload-rules && \
        sudo udevadm trigger && \
        ok "Android udev rules installed."
        SETUP_UDEV=1
    else
        warn "Skipped. Android USB devices may not be detected."
    fi
fi

# ── CHECK 7: plugdev group ────────────────────────────────────────────────
if groups 2>/dev/null | grep -qw plugdev; then
    ok "User in 'plugdev' group  (USB permissions)"
else
    warn "User not in 'plugdev' group — ADB may fail"
    if ! getent group plugdev >/dev/null 2>&1; then
        warn "Group 'plugdev' does not exist."
        if ask_yn "Create 'plugdev' group? (requires sudo)"; then
            sudo groupadd plugdev && ok "Created plugdev group." || warn "Failed to create group."
        fi
    fi
    if ask_yn "Add current user to 'plugdev' group? (requires sudo + re-login)"; then
        sudo usermod -aG plugdev "$USER" && \
        ok "Added to plugdev. Re-login for it to take effect." || \
        warn "Failed. Run manually: sudo usermod -aG plugdev $USER"
    fi
fi

# ── CHECK 8: FFmpeg runtime libraries (required for video decode) ──────────
FFMPEG_OK=0
if has_lib "libavcodec.so"; then
    FFMPEG_OK=1
fi
if [ $FFMPEG_OK -eq 1 ]; then
    ok "FFmpeg libraries  (H.264 video decode)"
else
    warn "FFmpeg libraries NOT found — video decode will NOT work!"
    warn "  Apps will show a black screen without FFmpeg."
    case $DISTRO in
        fedora)        warn "  Fix: sudo dnf install ffmpeg-libs" ;;
        ubuntu|debian) warn "  Fix: sudo apt install libavcodec-extra libswscale5 libavutil57" ;;
        arch)          warn "  Fix: sudo pacman -S ffmpeg" ;;
        opensuse)      warn "  Fix: sudo zypper install libavcodec6x" ;;
    esac
    if ask_yn "Install FFmpeg libraries now?"; then
        case $DISTRO in
            fedora)        sudo dnf install -y ffmpeg-libs ;;
            ubuntu|debian) sudo apt-get install -y libavcodec-extra ;;
            arch)          sudo pacman -S --noconfirm ffmpeg ;;
            opensuse)      sudo zypper install -y libavcodec6x ;;
        esac
        ok "FFmpeg libraries installed."
    fi
fi

# ── Decision gate ─────────────────────────────────────────────────────────
echo  "  ─────────────────────────────────────────────────────"

if [ $MISSING -gt 0 ]; then
    echo -e "\n${RED}${BLD}  Cannot launch: $MISSING critical dependency missing.${NC}"
    echo    "  Re-run this script after installing the required packages."
    echo
    exit 1
fi

echo -e "${GRN}${BLD}  All critical checks passed — launching Android Dex...${NC}\n"

# ── LAUNCH ──────────────────────────────────────────────────────────────────
chmod +x "$APP_BINARY"

info "Launching with Hardware Acceleration..."
if [ $DEBUG_MODE -eq 1 ]; then
    "$APP_BINARY" "${PASS_ARGS[@]}" 2>> "$LOG_FILE"
else
    "$APP_BINARY" "${PASS_ARGS[@]}"
fi
EXIT_CODE=$?

# Stage 2: Fallback to Software Rendering (llvmpipe - fast software)
# Only triggered if Stage 1 crashed (Exit != 0) AND was not cancelled by user (Exit != 130)
if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 130 ] && [ $EXIT_CODE -ne 127 ]; then
    warn "Hardware rendering failed (Code $EXIT_CODE). Attempting Software Rendering (llvmpipe)..."
    
    export LIBGL_ALWAYS_SOFTWARE=1
    export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
    export GALLIUM_DRIVER=llvmpipe
    
    if [ $DEBUG_MODE -eq 1 ]; then
        "$APP_BINARY" "${PASS_ARGS[@]}" 2>> "$LOG_FILE"
    else
        "$APP_BINARY" "${PASS_ARGS[@]}"
    fi
    EXIT_CODE=$?
fi

# Stage 3: Extreme Fallback (softpipe - slow but 100% compatible)
if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 130 ] && [ $EXIT_CODE -ne 127 ]; then
    warn "Low-level software rendering failed. Attempting Extreme Compatibility mode (softpipe)..."
    
    export GALLIUM_DRIVER=softpipe
    export WEBKIT_DISABLE_COMPOSITING_MODE=1
    
    if [ $DEBUG_MODE -eq 1 ]; then
        "$APP_BINARY" "${PASS_ARGS[@]}" 2>> "$LOG_FILE"
    else
        "$APP_BINARY" "${PASS_ARGS[@]}"
    fi
    EXIT_CODE=$?
fi

# Final Outcome Check
if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 130 ]; then
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    err "Critical failure: App could not launch even in fallback mode."
    info "Report issue at: https://github.com/Shrey113/Android-Dex/issues"
    info "Please attach the terminal output above to your report."
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
fi

# ── Show debug log file path on exit ──────────────────────────────────────
if [ $DEBUG_MODE -eq 1 ]; then
    echo
    echo -e "${CYN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BLD}📄 Debug log saved to:${NC}"
    echo -e "  ${GRN}$LOG_FILE${NC}"
    if [ -f "$LOG_FILE" ]; then
        LOG_SIZE=$(du -h "$LOG_FILE" | cut -f1)
        LOG_LINES=$(wc -l < "$LOG_FILE")
        echo -e "  ${YLW}Size: ${LOG_SIZE}  |  Lines: ${LOG_LINES}${NC}"
    fi
    echo -e "${CYN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
fi

exit $EXIT_CODE
