#!/bin/bash

clear

# ==========================================
# COLOR CODES & UI
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

WORKDIR="${WORKDIR:-$HOME/.qemucloud}"
PID_FILE="${WORKDIR}/qemu.pid"
ENV_FILE="${WORKDIR}/.vps_env"

type_effect() {
    local text="$1"
    local delay="$2"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

loading_bar() {
    local title="$1"
    echo -ne "${YELLOW}⏳ $title ${NC}[          ]"
    sleep 0.2
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[===       ]"
    sleep 0.2
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[======    ]"
    sleep 0.2
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[========= ]"
    sleep 0.2
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[==========]"
    echo -e " ${GREEN}DONE!${NC}"
}

# Root/Sudo detection
if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

get_accel_flags() {
    if [ -w /dev/kvm ]; then
        echo "-enable-kvm -cpu host"
    else
        echo "-cpu max"
    fi
}

show_menu() {
    clear
    echo ""
    echo -e "${BLUE}                         INFINITE LABS${NC}"
    echo -e "${BLUE}                    ─────────────────────${NC}"
    echo -e "${WHITE}                 SECURE VPS CONTROL PANEL${NC}"
    echo ""
    echo -e "${BLUE}     ┌──────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}     │  ${WHITE}SYSTEM${BLUE}                                          │${NC}"
    if [ -w /dev/kvm ]; then
        echo -e "${BLUE}     │  ${GREEN}● KVM ACCELERATED${BLUE}   ${CYAN}QEMU/KVM${BLUE}    ${YELLOW}PORT FORWARD${BLUE}   │${NC}"
    else
        echo -e "${BLUE}     │  ${YELLOW}● TCG EMULATION${BLUE}     ${CYAN}QEMU (NO-KVM)${BLUE}   ${YELLOW}PORT FORWARD${BLUE}   │${NC}"
    fi
    echo -e "${BLUE}     └──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${BLUE}     ┌─────────────────── ${WHITE}MAIN MENU${BLUE} ─────────────────────┐${NC}"
    echo -e "${BLUE}     │                                                  │${NC}"
    echo -e "${BLUE}     │   ${CYAN}01${BLUE}  ›  ${WHITE}CREATE / PROVISION VPS${BLUE}                 │${NC}"
    echo -e "${BLUE}     │       ${WHITE}Deploy Ubuntu 24.04 / Debian / Alpine VM${BLUE}   │${NC}"
    echo -e "${BLUE}     │                                                  │${NC}"
    echo -e "${BLUE}     │   ${CYAN}02${BLUE}  ›  ${WHITE}START / ATTACH VPS${BLUE}                     │${NC}"
    echo -e "${BLUE}     │       ${WHITE}Boot existing VM instance${BLUE}                  │${NC}"
    echo -e "${BLUE}     │                                                  │${NC}"
    echo -e "${BLUE}     │   ${CYAN}03${BLUE}  ›  ${WHITE}NETWORK PORT SETTINGS${BLUE}                  │${NC}"
    echo -e "${BLUE}     │       ${WHITE}Configure Host & Guest SSH ports${BLUE}           │${NC}"
    echo -e "${BLUE}     │                                                  │${NC}"
    echo -e "${BLUE}     │   ${CYAN}04${BLUE}  ›  ${WHITE}STOP & CLEANUP VPS${BLUE}                     │${NC}"
    echo -e "${BLUE}     │       ${WHITE}Safely terminate VM and delete data${BLUE}        │${NC}"
    echo -e "${BLUE}     │                                                  │${NC}"
    echo -e "${BLUE}     │   ${CYAN}05${BLUE}  ›  ${WHITE}EXIT${BLUE}                                    │${NC}"
    echo -e "${BLUE}     │                                                  │${NC}"
    echo -e "${BLUE}     └──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -ne "${CYAN}     Select option › [1-5]: ${NC}"
    read -r CHOICE

    case "$CHOICE" in
        1) create_vps ;;
        2) start_vps ;;
        3) configure_tcp ;;
        4) clean_vps ;;
        5) clear; exit 0 ;;
        *) echo -e "${RED}     ❌ Invalid choice.${NC}"; sleep 1; show_menu ;;
    esac
}

create_vps() {
    clear
    echo ""
    echo -e "${BLUE}     ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}     ║              ${WHITE}CREATE NEW SECURE VPS${BLUE}               ║${NC}"
    echo -e "${BLUE}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "     ${WHITE}Select OS Image:${NC}"
    echo -e "     ${CYAN}1)${NC} Debian 13 (Trixie - Recommended, Fast & Modern)"
    echo -e "     ${CYAN}2)${NC} Debian 12 (Bookworm - Oldstable, Lean)"
    echo -e "     ${CYAN}3)${NC} Alpine Linux 3.20 (Ultra-light, ~50MB)"
    echo -e "     ${CYAN}4)${NC} Ubuntu 24.04 LTS (Noble - General Dev)"
    echo -ne "${CYAN}     Choice [1-4, default: 1]: ${NC}"
    read -r OS_CHOICE
    OS_CHOICE=${OS_CHOICE:-1}

    case "$OS_CHOICE" in
        2)
            OS_NAME="Debian 12"
            IMG_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
            ;;
        3)
            OS_NAME="Alpine 3.20"
            IMG_URL="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/cloud/nocloud_alpine-3.20.0-x86_64-bios-cloudinit-r0.qcow2"
            ;;
        4)
            OS_NAME="Ubuntu 24.04"
            IMG_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
            ;;
        *)
            OS_NAME="Debian 13"
            IMG_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
            ;;
    esac

    echo -ne "${CYAN}     🔹 Enter RAM Size in GB (default: 4): ${NC}"
    read -r RAM_GB
    RAM_GB=${RAM_GB:-4}

    echo -ne "${CYAN}     🔹 Enter CPU Cores (default: 2): ${NC}"
    read -r CPU_CORES
    CPU_CORES=${CPU_CORES:-2}

    echo -ne "${CYAN}     🔹 Enter Disk Space to ADD in GB (default: 10): ${NC}"
    read -r DISK_ADD
    DISK_ADD=${DISK_ADD:-10}

    echo -ne "${CYAN}     🔹 Create Username (default: dev): ${NC}"
    read -r USER_NAME
    USER_NAME=${USER_NAME:-dev}

    echo -ne "${CYAN}     🔹 Create Password (min 6 chars recommended): ${NC}"
    read -rs USER_PASS
    echo ""
    if [ -z "$USER_PASS" ]; then
        USER_PASS="Pass_$(tr -dc A-Za-z0-9 </dev/urandom | head -c 10)"
        echo -e "${YELLOW}     Generated secure password: ${WHITE}$USER_PASS${NC}"
    fi

    echo -ne "${CYAN}     🔹 Enter GROQ API Key for Nvim AI Mentor (optional, Enter to skip): ${NC}"
    read -rs GROQ_KEY
    echo ""

    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=22

    echo ""
    echo -e "${YELLOW}     ⏳ Installing required dependencies...${NC}"
    $SUDO_CMD apt-get update -qq > /dev/null 2>&1 || true
    $SUDO_CMD apt-get install -y -qq \
        qemu-system-x86 \
        qemu-utils \
        wget \
        cloud-image-utils \
        curl \
        lsof > /dev/null 2>&1 || true

    mkdir -p "$WORKDIR" 2>/dev/null || $SUDO_CMD mkdir -p "$WORKDIR" 2>/dev/null || true

    VM_IMG="${WORKDIR}/disk.qcow2"
    SEED_IMG="${WORKDIR}/seed.img"
    USER_DATA="${WORKDIR}/user-data"

    # Download or verify existing image
    if [ -f "$VM_IMG" ]; then
        IMG_FMT=$(qemu-img info "$VM_IMG" 2>/dev/null | grep -i 'file format:' | awk '{print $3}')
        if [ -z "$IMG_FMT" ]; then
            echo -e "${YELLOW}     ⚠️ Corrupt or incomplete image detected. Purging...${NC}"
            rm -f "$VM_IMG"
        else
            echo -e "${GREEN}     ✅ Valid ${IMG_FMT} image detected: ${VM_IMG}${NC}"
        fi
    fi

    if [ ! -f "$VM_IMG" ]; then
        echo -e "${YELLOW}     📥 Downloading ${OS_NAME} Cloud Image...${NC}"
        if command -v wget >/dev/null 2>&1; then
            wget --show-progress -O "$VM_IMG" "$IMG_URL" || curl -L --progress-bar -o "$VM_IMG" "$IMG_URL"
        else
            curl -L --progress-bar -o "$VM_IMG" "$IMG_URL"
        fi
    fi
    chmod 600 "$VM_IMG" 2>/dev/null || true

    # Dynamically package custom cloud-config if found locally
    CONFIG_DIR=""
    if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
        DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
        if [ -d "${DIR_PATH}/cloud-config" ]; then
            CONFIG_DIR="${DIR_PATH}/cloud-config"
        fi
    fi
    if [ -z "$CONFIG_DIR" ] && [ -d "./cloud-config" ]; then
        CONFIG_DIR="$(pwd)/cloud-config"
    fi

    EMBEDDED_B64="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"

    CONFIG_B64=""
    if [ -d "$CONFIG_DIR" ]; then
        CONFIG_B64=$(tar -czf - -C "$CONFIG_DIR" . | base64 -w 0)
    else
        CONFIG_B64="$EMBEDDED_B64"
    fi

    loading_bar "Generating Secure Cloud-Init Config (Custom Zsh + Nvim)"
    cat <<EOF > "$USER_DATA"
#cloud-config
ssh_pwauth: true
packages:
  - zsh
  - curl
  - git
  - neovim
  - ripgrep
  - fd-find
  - fzf
  - bat
  - eza
  - build-essential
  - python3
  - python3-venv
  - nodejs
  - npm
  - zsh-autosuggestions
  - zsh-syntax-highlighting
users:
  - name: ${USER_NAME}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/zsh
    lock_passwd: false
chpasswd:
  list: |
    ${USER_NAME}:${USER_PASS}
  expire: false
write_files:
  - path: /tmp/dev-config.tar.gz
    encoding: b64
    content: ${CONFIG_B64}
    permissions: '0600'
  - path: /home/${USER_NAME}/.config/groq.env
    owner: ${USER_NAME}:${USER_NAME}
    permissions: '0600'
    content: |
      GROQ_API_KEY=${GROQ_KEY}
runcmd:
  # Setup user home and config directories
  - mkdir -p /home/${USER_NAME}/.config
  - tar -xzf /tmp/dev-config.tar.gz -C /home/${USER_NAME}/
  - if [ -d /home/${USER_NAME}/nvim ]; then mv /home/${USER_NAME}/nvim /home/${USER_NAME}/.config/nvim; fi
  # Install Starship prompt for Zsh
  - if ! command -v starship >/dev/null 2>&1; then curl -sS https://starship.rs/install.sh | sh -s -- -y; fi
  # Install Astral uv (Python package & tool manager)
  - if ! command -v uv >/dev/null 2>&1; then curl -LsSf https://astral.sh/uv/install.sh | env CARGO_DIST_FORCE_INSTALL_DIR=/usr/local/bin sh; fi
  # Symlink Debian/Ubuntu utility names
  - if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then ln -sf \$(which batcat) /usr/local/bin/bat; fi
  - if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then ln -sf \$(which fdfind) /usr/local/bin/fd; fi
  # Ensure root also has zsh shell and permissions are correct
  - chsh -s /bin/zsh root
  - chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}
  - rm -f /tmp/dev-config.tar.gz
EOF
    chmod 600 "$USER_DATA" 2>/dev/null || true

    if command -v cloud-localds >/dev/null 2>&1; then
        cloud-localds "$SEED_IMG" "$USER_DATA" > /dev/null 2>&1
    elif command -v genisoimage >/dev/null 2>&1; then
        genisoimage -output "$SEED_IMG" -volid cidata -joliet -rock "$USER_DATA" > /dev/null 2>&1
    elif command -v mkisofs >/dev/null 2>&1; then
        mkisofs -output "$SEED_IMG" -volid cidata -joliet -rock "$USER_DATA" > /dev/null 2>&1
    fi
    chmod 600 "$SEED_IMG" 2>/dev/null || true

    loading_bar "Expanding Virtual Disk (+${DISK_ADD}G)"
    qemu-img resize "$VM_IMG" "+${DISK_ADD}G" > /dev/null 2>&1 || true

    save_env
    boot_qemu
}

configure_tcp() {
    clear
    load_env
    echo ""
    echo -e "${BLUE}     ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}     ║             ${WHITE}NETWORK CONFIGURATION${BLUE}             ║${NC}"
    echo -e "${BLUE}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "     Current Host Port   : ${CYAN}${TCP_HOST_PORT:-2222}${NC}"
    echo -e "     Current Guest Port  : ${CYAN}${TCP_GUEST_PORT:-22}${NC}"
    echo ""

    echo -ne "${CYAN}     🔹 Enter NEW Host Port (Default: 2222): ${NC}"
    read -r NEW_HOST_PORT
    TCP_HOST_PORT=${NEW_HOST_PORT:-2222}

    echo -ne "${CYAN}     🔹 Enter Guest Port (Default SSH: 22): ${NC}"
    read -r NEW_GUEST_PORT
    TCP_GUEST_PORT=${NEW_GUEST_PORT:-22}

    save_env
    echo -e "${GREEN}     ✅ Network rule saved.${NC}"
    sleep 1
    show_menu
}

save_env() {
    mkdir -p "$WORKDIR"
    cat <<EOF > "$ENV_FILE"
OS_NAME="${OS_NAME:-Debian 13}"
RAM_GB=${RAM_GB:-4}
CPU_CORES=${CPU_CORES:-2}
USER_NAME="${USER_NAME:-dev}"
USER_PASS="${USER_PASS}"
TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}
EOF
    chmod 600 "$ENV_FILE"
}

load_env() {
    if [ -f "$ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi
}

boot_qemu() {
    load_env
    VM_IMG="${WORKDIR}/disk.qcow2"
    SEED_IMG="${WORKDIR}/seed.img"

    if [ ! -f "$VM_IMG" ] || [ ! -f "$SEED_IMG" ]; then
        echo -e "${RED}❌ VM files not found in ${WORKDIR}. Run option 1 first.${NC}"
        sleep 2
        show_menu
        return
    fi

    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}
    RAM_VALUE="${RAM_GB:-4}G"
    ACCEL_OPTS=$(get_accel_flags)

    clear
    echo ""
    echo -e "${BLUE}     ╔══════════════════════════════════════════════════╗${NC}"
    type_effect "     🚀 STARTING SECURE VM..." 0.01
    echo -e "${BLUE}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}     ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}     ║              ${GREEN}✓ VM INSTANCE READY${BLUE}                 ║${NC}"
    echo -e "${BLUE}     ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}     ║ ${WHITE}OS       : ${CYAN}${OS_NAME:-Ubuntu}${BLUE}                                ║${NC}"
    echo -e "${BLUE}     ║ ${WHITE}User     : ${CYAN}${USER_NAME:-dev}${BLUE}                                   ║${NC}"
    echo -e "${BLUE}     ║ ${WHITE}Password : ${CYAN}${USER_PASS}${BLUE}                                  ║${NC}"
    echo -e "${BLUE}     ║ ${WHITE}Resources: ${CYAN}${RAM_VALUE} RAM | ${CPU_CORES:-2} Cores${BLUE}                  ║${NC}"
    echo -e "${BLUE}     ║ ${WHITE}Port Fwd : ${YELLOW}127.0.0.1:${TCP_HOST_PORT} → VM:${TCP_GUEST_PORT}${BLUE}             ║${NC}"
    echo -e "${BLUE}     ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}     ║ ${WHITE}👉 Connect SSH:${BLUE}                                  ║${NC}"
    echo -e "${BLUE}     ║ ${CYAN}ssh ${USER_NAME:-dev}@127.0.0.1 -p ${TCP_HOST_PORT}${BLUE}                 ║${NC}"
    echo -e "${BLUE}     ║                                                  ║${NC}"
    echo -e "${BLUE}     ║ ${WHITE}Press Ctrl+A then X to exit QEMU console${BLUE}       ║${NC}"
    echo -e "${BLUE}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    # Auto-detect image format (qcow2 vs raw)
    IMG_FMT=$(qemu-img info "$VM_IMG" 2>/dev/null | grep -i 'file format:' | awk '{print $3}')
    IMG_FMT=${IMG_FMT:-qcow2}

    # Run QEMU foreground console; track PID in background if needed
    # shellcheck disable=SC2086
    exec qemu-system-x86_64 \
        $ACCEL_OPTS \
        -drive file="${VM_IMG}",format="${IMG_FMT}",if=virtio \
        -drive file="${SEED_IMG}",format=raw,if=virtio \
        -m "$RAM_VALUE" \
        -smp "${CPU_CORES:-2}" \
        -nographic \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:${TCP_HOST_PORT}-:${TCP_GUEST_PORT} \
        -device virtio-net-pci,netdev=net0
}

start_vps() {
    load_env
    if [ -f "${WORKDIR}/disk.qcow2" ] && [ -f "${WORKDIR}/seed.img" ]; then
        boot_qemu
    else
        echo -e "${RED}❌ No existing VM configuration found in ${WORKDIR}.${NC}"
        sleep 2
        show_menu
    fi
}

clean_vps() {
    clear
    echo ""
    echo -e "${RED}     ⚠ CLEAN & PURGE VPS WORKSPACE${NC}"
    echo -ne "${YELLOW}     Are you sure you want to delete VM in ${WORKDIR}? (y/N): ${NC}"
    read -r CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        # Terminate any running QEMU instance for this image
        pkill -f "qemu-system-x86_64.*${WORKDIR}/disk.qcow2" || true
        rm -rf "${WORKDIR:?}"/* "${WORKDIR:?}"/.* 2>/dev/null || true
        echo -e "${GREEN}     ✅ VM cleaned and storage released.${NC}"
    else
        echo -e "${YELLOW}     Clean aborted.${NC}"
    fi
    sleep 2
    show_menu
}

show_menu

