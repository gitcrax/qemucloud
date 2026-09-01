# ⚡ QEMUCloud

> Lightweight, secure, self-contained Cloud VPS environment optimized for CLI development, fast Zsh, and Neovim AI Mentor.

[![Ubuntu 26.04](https://img.shields.io/badge/OS-Ubuntu%2026.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://cloud-images.ubuntu.com)
[![Debian 13](https://img.shields.io/badge/OS-Debian%2013-D70A53?logo=debian&logoColor=white)](https://cloud.debian.org)
[![QEMU/KVM](https://img.shields.io/badge/Virtualization-QEMU%20%2F%20KVM-FF6600?logo=qemu&logoColor=white)](https://www.qemu.org)
[![Neovim](https://img.shields.io/badge/Editor-Neovim%200.11+-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![Starship](https://img.shields.io/badge/Prompt-Starship-DD0B78?logo=starship&logoColor=white)](https://starship.rs)
[![Astral uv](https://img.shields.io/badge/Python-Astral%20uv-7E57C2?logo=python&logoColor=white)](https://astral.sh)

---

## 🚀 Quickstart

Run directly inside your cloud container (Codespaces, Gitpod, Daytona, AWS, VPS):

```bash
bash <(curl -sL https://raw.githubusercontent.com/<YOUR_USER>/<YOUR_REPO>/main/install.sh)
```

*Zero-dependency & self-contained: packages and bootstraps everything in a single step.*

---

## 🛠️ What's Inside?

| Component | Stack | Purpose |
|---|---|---|
| **Base OS** | Ubuntu 26.04 LTS / Debian 13 | Latest LTS with modern kernel, glibc, and native packages |
| **Virtualization** | QEMU + KVM Auto-Detect | Near-native speed with `/dev/kvm` hardware acceleration |
| **Shell** | Zsh + Starship | Sub-5ms startup, substring history search, and git status prompt |
| **CLI Toolkit** | `eza`, `bat`, `fzf`, `ripgrep`, `fd`, `uv` | Modern, high-performance replacements for core GNU utilities |
| **Editor** | Neovim (Lazy.nvim) | Complete modular CLI IDE with LSP, Treesitter, and Mason |
| **AI Mentor** | CodeCompanion + Groq | Strict teaching & review assistant (explains & hints; never writes for you) |

---

## 🔒 Security Hardening

Unlike typical community VPS launch scripts, **QEMUCloud** is hardened:
* **No Host Shell Exposing Tunnels**: Removed unauthenticated host web shell backdoors (`sshx`).
* **Localhost Port Forwarding**: VM SSH is bound strictly to `127.0.0.1:2222`. Use your cloud workspace port-forwarding tab or Cloudflare Access tunnel.
* **Least Privilege Permissions**: All disk images, cloud-init seeds, and API keys are stored with `chmod 600`.
* **Safe Process Lifecycle**: Eliminates blind `pkill sh` commands; targets VM instances safely.

---

## ⌨️ Developer Cheat Sheet

### 1. Connecting to the VM
From the host terminal:
```bash
ssh dev@127.0.0.1 -p 2222
```
*To disconnect / exit QEMU foreground console:* Press `Ctrl + A`, then press `X`.

---

### 2. Shell & CLI Enhancements
* **Prompt**: Native Starship prompt with execution timing and git branch details.
* **History Substring Search**: Type part of any command and press `Up` / `Down` (or `Ctrl+P` / `Ctrl+N`).
* **Aliases**:
  * `ls` / `ll` / `l` → `eza --group-directories-first`
  * `cat` → `bat`
  * `v` / `nv` → `nvim`
  * `gs` / `gd` / `gl` → `git status` / `git diff` / `git log`

---

### 3. Neovim & AI Mentor Keymaps

| Keybind | Mode | Action |
|---|---|---|
| `<Space>` | Normal | Leader key |
| `<leader>a` | Normal | Open **AI Mentor Chat** window |
| `<leader>c` | Normal | Open **AI Mentor Actions** palette |
| `gcm` | Visual | **Mentor Review Selection**: points out bugs, explains why, gives hints |
| `gd` | Normal | Jump to LSP definition |
| `gr` | Normal | Find LSP references |
| `K` | Normal | LSP Hover documentation |
| `<leader>rn`| Normal | LSP Rename symbol |
| `<leader>ca`| Normal | LSP Code Action |
| `<leader>F` | Normal | Format buffer (async) |

---

## 📁 Repository Structure

```text
├── install.sh                  # Interactive VPS manager & cloud-init provisioner
├── README.md                   # Documentation & quickstart guide
└── cloud-config/               # Dotfiles source tree
    ├── .zshrc                  # Lightweight Zsh configuration
    └── nvim/                   # Modular Neovim configuration
        ├── init.lua            # Bootstrap & Lazy.nvim setup
        ├── lazy-lock.json      # Plugin version lockfile
        └── lua/
            ├── config/         # Options, keymaps, autocmds
            └── plugins/        # LSP, Treesitter, AI Mentor, Fuzzy, Format
```

---

## ⚙️ Manual Clone & Customization

If you prefer to clone and customize dotfiles before launching:

```bash
git clone https://github.com/<YOUR_USER>/<YOUR_REPO>.git
cd <YOUR_REPO>
chmod +x install.sh
./install.sh
```

---

## 📜 License

MIT License. Feel free to fork and customize!
