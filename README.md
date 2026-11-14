<div align="center">

# Fedora Workstation Post-Install Suite

### Seamless post-install automation, developer orchestration, and interactive control center for Fedora Workstation.

[![License](https://img.shields.io/github/license/AIJosue/Ansible-Playbook-Fedora-Workstation?style=flat-square&color=gray)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-2ecc71?style=flat-square)](#)
[![Ansible](https://img.shields.io/badge/Ansible-Ready-007AFF?style=flat-square)](#)
[![Fedora](https://img.shields.io/badge/Fedora-41%20%7C%20Rawhide-51A0D5?style=flat-square)](#)

</div>

---

## What Is This Project?

**Fedora Workstation Post-Install Suite** is a declarative **Ansible-based workstation orchestrator and terminal control center** built around Apple Human Interface Guidelines: **Clarity**, **Deference**, and **Depth**.

It automates the transition from a stock Fedora installation to a production-grade development system in a single command—configuring repositories, development toolchains, rootless container bridges, kernel virtualization stacks, and user-space enhancements with zero manual friction.

---

## Architecture

The mindmap below outlines the architectural hierarchy and separation between root system provisioning and unprivileged user-space workflows:

```mermaid
mindmap
  root((Workstation Suite))
    Build & CI
      Ansible Playbook Engine
      Travis CI Validation
      tokless Code Intelligence
    Core System Tasks
      External Repositories
      Curated DNF Packages & Bloat Removal
      Flatpaks & Snaps Distribution
      Systemd Services & Docker Bridge
      Waydroid Android Subsystem
      Hardware udev Rules
    User Space Control
      launcher.sh Control Center
      gum Interactive Menus & Prompts
      virt-builder OS Generator
      Local AI & AppImage Hub
      PipeWire Audio Streaming
    Tech Stack
      Ansible & YAML
      Bash & gum
      KVM, QEMU & Libvirt
      Podman & OCI
```

---

## Why Does It Exist?

Manually provisioning a fresh Fedora workstation requires repetitive, error-prone configuration across fragmented package ecosystems (DNF, Flathub, Snapcraft, AppImages), virtualization settings, and shell environments. 

This project delivers a **reproducible, declarative workstation standard** that:

> [!NOTE]
> **Core Engineering Tenets**
> * **Strict Privilege Boundary**: Elevated (`sudo`) system-level provisioning is strictly decoupled from unprivileged user environments (`launcher.sh`).
> * **Cognitive Deference**: UI tools emphasize content over chrome; `gum` fuzzy filtering, confirmations and spinners reduce mental overhead.
> * **Reproducible Infrastructure**: Version-controlled VM templates, Vagrant sandboxes, and Ansible plays allow identical environments across machines.

---

## How It Works

The suite executes a 12-stage sequential pipeline against the local workstation, configuring official repositories, upgrading base packages, establishing container runtime sockets, and provisioning hardware access rules.

Once provisioned, users interact with the system via `launcher.sh`—an interactive terminal control center utilizing **Apple HIG design patterns** (rounded borders, high-contrast indicators, right-anchored inspector previews, and modal confirmations).

### Technology Breakdown

| Technology | Role | Purpose |
| :--- | :--- | :--- |
| **Ansible** | Orchestration | Declarative task automation, idempotency, and host configuration |
| **Fedora Linux** | Host Platform | Modern Linux workstation base with DNF, systemd, and Btrfs |
| **gum** | User Interface | Charm gum menus, fuzzy filter, checkbox lists, spinners, tables and prompts (`sudo dnf install gum`) |
| **KVM / QEMU / Libvirt** | Hypervisor | Hardware-accelerated virtual machines, bridge networking, and `virt-builder` |
| **Podman** | Containers | Rootless container engine with `/var/run/docker.sock` API bridge |
| **Waydroid** | Android Subsystem | Containerized LineageOS with libndk ARM translation and Widevine DRM |
| **Homebrew & Pixi** | Package Managers | Unprivileged command-line developer tools and Conda environments |
| **ujust & Starship** | Terminal Experience | Universal Blue task runner, terminal bling, and cross-shell prompt |

---

## Repository Structure

<details>
<summary><strong>View project file tree</strong></summary>

```text
Ansible-Playbook-Fedora-Workstation/
├── local.yml                      # Main playbook definition and variable toggles
├── handlers/
│   └── main.yml                   # System handlers (udev rules reload)
├── tasks/
│   ├── repositories.yml           # External YUM/DNF repository configurations
│   ├── update.yml                 # System package upgrades
│   ├── packages.yml               # DNF packages, bloat removal & Pinokio RPM
│   ├── flatpaks.yml               # Flathub & Fedora OCI Flatpak applications
│   ├── snaps.yml                  # Classic & standard confinement Snap applications
│   ├── services.yml               # Systemd services, sockets, firewalld & libvirt defaults
│   ├── udev.yml                   # Gamepad, joystick & VR udev rules
│   ├── waydroid.yml               # Waydroid integration, Polkit rules & defaults
│   ├── homebrew.yml               # Unprivileged Linuxbrew installation & PATH
│   ├── users-groups.yml           # User accounts, groups & desktop launcher deployment
│   ├── ujust.yml                  # ujust recipes, Starship prompt & Bluefin bling
│   └── initialize.yml             # System hostname, AppImages dir & virtualization paths
├── launcher.sh                    # HIG-compliant interactive user control center (gum)
├── Scripts/
│   ├── packages.sh                # Core DNF package installation script
│   └── user.sh                    # Helper to launch shell as unprivileged desktop user
├── files/
│   ├── udev/                      # Hardware udev rule definitions (*.rules)
│   ├── ujust/                     # Bluefin ujust task recipes, bling scripts & configs
│   ├── vagrant/
│   │   ├── ubuntu/                # Ubuntu 24.04 LTS desktop libvirt VM
│   │   └── yunohost/              # Debian 12 YunoHost self-hosting testbed
│   ├── vms/                       # Libvirt KVM guest XML templates
│   │   ├── Android.xml
│   │   ├── Linux.xml
│   │   └── Windows.xml
│   └── waydroid/                  # Bazzite Waydroid container scripts, GPU tool & Polkit
├── logs/                          # Installation logs directory
├── travis.yml                     # Syntax validation CI configuration
├── LICENSE                        # Repository license
└── README.md                      # Documentation
```

</details>

---

## Development Workflow

The development lifecycle follows a strict review, lint, and verification pipeline:

```mermaid
gantt
    title Development & Deployment Pipeline
    dateFormat  YYYY-MM-DD
    section Implementation
        Task & Script Authoring    :a1, 2026-01-01, 1d
        Local Syntax & Dry-Run     :a2, after a1, 1d
        Pull Request Submission    :a3, after a2, 1d
    section Continuous Integration
        Automated Syntax Check     :b1, after a3, 1d
        Release & Host Deployment  :b2, after b1, 1d
```

---

## How to Run Locally

<details open>
<summary><strong>Quickstart Instructions</strong></summary>

### Quick One-Liner (Remote Bootstrap)
Bootstrap and launch immediately on a fresh Fedora Workstation without manually cloning first:
```bash
curl -SL https://github.com/AIJosue/Ansible-Playbook-Fedora-Workstation/raw/refs/heads/main/launcher.sh | bash
```

### 1. Prerequisites (Manual Setup)
Ensure Ansible and Git are available:
```bash
sudo dnf install -y ansible git gum
```

### 2. Clone Repository
```bash
git clone https://github.com/AIJosue/Ansible-Playbook-Fedora-Workstation.git
cd Ansible-Playbook-Fedora-Workstation
```

### 3. Verify & Execute Playbook
Run syntax check, then execute the declarative setup (full playbook or selective tags):
```bash
ansible-playbook local.yml --syntax-check
ansible-playbook local.yml --ask-become-pass
# Or run specific sections using tags:
ansible-playbook local.yml --tags ujust --ask-become-pass
```

### 4. Launch User Control Center
Access the HIG-styled interactive utility anytime:
```bash
./launcher.sh
```

> [!TIP]
> Run `./launcher.sh --help` to list all direct non-interactive CLI flags (e.g. `--playbook`, `--ujust`, `--virt-builder`, `--waydroid`, `--libvirt-net`, `--appimages`, `--devpod`, `--dory`, `--prism`, `--localai`, `--updatetool`).

### 5. Customizing `launcher.sh`
All user-configurable paths, URLs, container names, ports, and defaults are grouped in the **User Configuration** block at the top of `launcher.sh` using `${VAR:-default}` syntax. You can either edit them directly in `launcher.sh` or override any setting per run via environment variables:

```bash
APPIMAGES_DIR=/opt/AppImages CUSTOM_SCRIPTS_DIR=~/scripts ./launcher.sh
```

| Category | Key Variables | Default |
| :--- | :--- | :--- |
| **Repository & Playbook** | `BOOTSTRAP_REPO_URL`, `BOOTSTRAP_TARGET_DIR`, `LEGACY_REPO_DIR`, `DESKTOP_LAUNCHER`, `PLAYBOOK_FILE` | `~/Code/Terminal/Ansible-Playbook-Fedora-Workstation`, `local.yml` |
| **UI & Theme** | `HIG_APPEARANCE` (`dark`\|`light`), `HIG_CONTRAST` (`standard`\|`high`) | `dark`, `standard` |
| **User Directories & Binaries** | `LOCAL_BIN_DIR`, `CACHE_BASE_DIR`, `DOWNLOADS_DIR`, `APPIMAGES_DIR`, `CUSTOM_SCRIPTS_DIR`, `BENCHMARKS_DIR`, `SSH_DIR` | `~/.local/bin`, `~/Downloads`, `~/AppImages`, `~/Code/Terminal/scripts` |
| **Package Managers & CLI** | `HOMEBREW_BIN`, `HOMEBREW_INSTALL_URL`, `PIXI_DIR`, `PIXI_BIN`, `PIXI_INSTALL_URL`, `STARSHIP_INSTALL_URL`, `UJUST_BIN`, `UBLUE_BLING_BIN` | `/home/linuxbrew/.linuxbrew/bin/brew`, `~/.pixi/bin/pixi`, `/usr/bin/ujust` |
| **AI / LLM & OpenClaw** | `KOBOLDCPP_BIN`, `KOBOLDCPP_PROMPTS_DIR`, `LLAMA_PRISM_DIR`, `LLAMA_DORY_DIR`, `LLAMA_DORY_REPO_URL`, `LLAMA_DORY_BRANCH`, `LLAMA_DORY_DEFAULT_MODEL`, `LLAMA_DORY_HOST`, `LLAMA_DORY_PORT`, `LOCALAI_DIR`, `OPENCLAW_BIN_DIR`, `OPENCLAW_INSTALL_URL`, `OPENCLAW_DEB_FALLBACK` | `~/AppImages/*`, `192.168.12.116:5001`, `~/.openclaw/bin` |
| **Distrobox & Flatpak** | `DISTROBOX_CONTAINER`, `DISTROBOX_IMAGE`, `FLATHUB_REMOTE_URL`, `FEDORA_FLATPAK_URI` | `ubuntu-toolbox`, `quay.io/toolbx/ubuntu-toolbox:latest` |
| **PipeWire & Waydroid** | `PIPEWIRE_DEFAULT_IP`, `PIPEWIRE_DEFAULT_PORT`, `WAYDROID_SYSTEM_OTA`, `WAYDROID_VENDOR_OTA`, `WAYDROID_IMAGES_DIR`, `WAYDROID_DATA_DIR`, `WAYDROID_CACHE_DIR` | `127.0.0.1:4713`, `/var/lib/waydroid/images`, `~/.local/share/waydroid` |
| **Virtualization & System** | `KVM_XML_DIR`, `VAGRANT_BASE_DIR`, `LIBVIRT_IMAGES_DIR`, `LIBVIRT_DEFAULT_DISK_SIZE`, `LIBVIRT_DEFAULT_PORT_RANGE`, `UDEV_RULES_DEST` | `~/Platforms/Virtualization/*`, `/var/lib/libvirt/images`, `20G`, `49152-65535`, `/etc/udev/rules.d` |

### 6. AppImage Hub & Local AI Engines
The AppImage Hub menu (`./launcher.sh --appimages`) provisions and manages standalone AppImages and local AI inference suites in `~/AppImages`:
* **Development & Tools**: DevPod (`~/.local/bin/devpod`), AppImageUpdate tool, Bionic, Darktable, Eden, Jan, LMMS, MuseScore Studio, QtScrcpy, Unsloth.
* **Local Inference Engines**:
  * **llama-prism**: Pre-compiled multi-backend llama.cpp binaries (CUDA, Vulkan, ROCm, SYCL, CPU) from PrismML.
  * **llama-dory**: Nemotron-Dory llama.cpp engine with loop/recurrent cache launch script.
  * **LocalAI**: Native binaries and containerized local model inference.
  * **KoboldCpp**: Single-file LLM inference executable.


</details>

---

## License

This project is licensed under the [MIT License](LICENSE).
