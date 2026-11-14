<div align="center">

# Fedora Workstation Post-Install Suite

[![License](https://img.shields.io/github/license/AIJosue/Ansible-Playbook-Fedora-Workstation?style=flat-square&labelColor=1C1C1E&color=8E8E93)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-34C759?style=flat-square&labelColor=1C1C1E)](#)
[![Powered by](https://img.shields.io/badge/Powered%20by-Ansible-007AFF?style=flat-square&labelColor=1C1C1E)](#)
[![Platform](https://img.shields.io/badge/Fedora-Workstation-5856D6?style=flat-square&labelColor=1C1C1E)](#)
[![Interface](https://img.shields.io/badge/UI-Apple%20HIG-5AC8FA?style=flat-square&labelColor=1C1C1E)](#)

**Turn a fresh Fedora install into a complete, ready-to-use workstation in minutes — no manual tweaking required.**

</div>

---

## What Is This Project?

**Fedora Workstation Post-Install Suite** is an all-in-one setup assistant and everyday **Control Center (`launcher.sh`)** for Fedora Linux.

Instead of spending hours hunting down installers, tweaking system settings, or memorizing terminal commands, you get a single automated setup followed by a clean, menu-driven dashboard. Whether you want creative apps, Android apps on your desktop, virtual machines, or private offline AI tools, everything is organized into simple, guided choices.

---

## Architecture

The diagram below shows how the suite separates behind-the-scenes system setup from your everyday Control Center:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#007AFF', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#0A84FF', 'secondaryColor': '#5856D6', 'secondaryTextColor': '#FFFFFF', 'tertiaryColor': '#34C759', 'tertiaryTextColor': '#FFFFFF', 'lineColor': '#8E8E93', 'background': '#1C1C1E', 'mainBkg': '#2C2C2E', 'nodeBkg': '#2C2C2E', 'nodeTextColor': '#F2F2F7'}}}%%
mindmap
  root((Fedora Workstation Suite))
    Automated Setup
      App Stores & Updates
      Hardware & Controller Support
      Background System Services
    Everyday Control Center
      Guided Menu Dashboard
      AppImage & Creative Hub
      Easy Top-of-File Settings
    Play & Create
      Android Apps via Waydroid
      Virtual Machines & Sandboxes
      Private Local AI Engines
    Build & Share
      Ansible Playbook
      Travis CI Checks
      One-Line Bootstrap
```

---

## Why Does It Exist?

Setting up a new computer is usually repetitive and frustrating. After installing Fedora, most people still have to enable extra app stores, install their favorite tools, configure controllers or audio, and set up virtual machines or AI apps by hand.

This project solves that by giving you a **repeatable, worry-free setup** that:

* **Saves Hours of Setup**: Installs your core apps, Flatpaks, Snaps, Homebrew tools, and system updates in one go.
* **Keeps Things Simple**: Replaces complex terminal commands with clean, interactive menus you can navigate with arrow keys.
* **Respects Your Choices**: Lets you run everything at once, pick only the parts you want, or customize paths and defaults right at the top of `launcher.sh`.

---

## How It Works

First, the **Ansible Playbook** (`local.yml`) prepares your system cleanly and safely—enabling app repositories, updating packages, setting up hardware rules, and installing your core tools.

After that, you use the **Control Center** (`./launcher.sh`) whenever you want to add new tools, launch local AI, manage Android apps, or spin up a virtual machine.

| Feature | What It Does For You |
| :--- | :--- |
| **One-Click System Setup** | Automatically updates Fedora and installs curated apps from DNF, Flathub, Snap, and Homebrew |
| **Interactive Control Center** | Clean, Apple HIG-inspired terminal menus (`gum`)—no command memorization needed |
| **AppImage Hub** | Browse, install, and update portable apps like Darktable, LMMS, MuseScore Studio, and Jan |
| **Private Local AI** | Set up and run offline AI engines (`llama-prism`, `llama-dory`, `LocalAI`, `KoboldCpp`, `OpenClaw`) |
| **Android on Desktop** | Guided **Waydroid** setup to run Android apps and games right inside Fedora |
| **Virtual Machines** | Ready-made Windows, Linux, and Android VM templates plus `virt-builder` and Vagrant sandboxes |
| **Audio & Hardware Ready** | PipeWire wireless audio streaming and plug-and-play support for gamepads and VR headsets |
| **Easy Customization** | All folders, URLs, ports, and theme options are grouped at the top of `launcher.sh` |

---

## Repository Structure

<details>
<summary><strong>Click to expand the full project structure</strong></summary>

```text
Ansible-Playbook-Fedora-Workstation/
├── local.yml                      # Main setup playbook and feature toggles
├── ansible.cfg                    # Ansible configuration
├── inventory.ini                  # Local machine target inventory
├── launcher.sh                    # Interactive Control Center (customizable at top of file)
├── roles/
│   ├── repositories/              # Extra software sources (RPM Fusion, Flathub, etc.)
│   ├── update/                    # System package updates
│   ├── packages/                  # Core desktop & CLI apps
│   ├── flatpaks/                  # Flathub & Fedora Flatpak apps
│   ├── snaps/                     # Snap Store apps
│   ├── services/                  # Background services, firewall & virtualization setup
│   ├── udev/                      # Plug-and-play gamepad, joystick & VR rules
│   ├── waydroid/                  # Android app subsystem setup
│   ├── homebrew/                  # Unprivileged Homebrew package manager
│   ├── users_groups/              # User permissions & desktop shortcut
│   ├── ujust/                     # Helpful task shortcuts & Starship terminal prompt
│   └── initialize/                # Hostname, AppImages folder & VM storage setup
├── Scripts/
│   ├── packages.sh                # Package installation helper
│   ├── sync_packages.py           # Package list sync helper
│   └── user.sh                    # Runs commands as your regular desktop user
├── files/
│   ├── udev/                      # Hardware rule files
│   ├── ujust/                     # ujust recipes & terminal bling configs
│   ├── vagrant/                   # Pre-configured Ubuntu & YunoHost test VMs
│   ├── vms/                       # Ready-to-import Android, Linux & Windows VM templates
│   └── waydroid/                  # Waydroid helper scripts & GPU tools
├── logs/                          # Setup logs
├── travis.yml                     # Automated syntax checks
├── LICENSE                        # Mozilla Public License 2.0
└── README.md                      # You are here
```

</details>

---

## Development Workflow

This timeline shows how updates are tested and delivered safely:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#007AFF', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#0A84FF', 'secondaryColor': '#5856D6', 'tertiaryColor': '#34C759', 'taskBkgColor': '#007AFF', 'taskTextColor': '#FFFFFF', 'activeTaskBkgColor': '#5856D6', 'activeTaskBorderColor': '#5E5CE6', 'doneTaskBkgColor': '#34C759', 'doneTaskBorderColor': '#30D158', 'gridColor': '#48484A', 'sectionBkgColor': '#2C2C2E', 'altSectionBkgColor': '#1C1C1E', 'titleColor': '#F2F2F7', 'textColor': '#F2F2F7'}}}%%
gantt
    title Update to Release Pipeline
    dateFormat  YYYY-MM-DD
    section Authoring
        Update Playbook & Launcher :a1, 2026-01-01, 1d
        Local Check & Dry Run      :a2, after a1, 1d
    section Verification
        Automated Syntax Check     :b1, after a2, 1d
        Publish to Main            :b2, after b1, 1d
```

---

## How to Run Locally

<details open>
<summary><strong>Click to expand setup instructions</strong></summary>

### Option A: Fast One-Line Setup (Recommended)
Run this in your Fedora terminal to download everything and open the Control Center automatically:
```bash
curl -SL https://github.com/AIJosue/Ansible-Playbook-Fedora-Workstation/raw/refs/heads/main/launcher.sh | bash
```

### Option B: Step-by-Step Setup

1. **Install prerequisites** (`ansible`, `git`, and `gum` for the menus):
```bash
sudo dnf install -y ansible git gum
```

2. **Download the project**:
```bash
git clone https://github.com/AIJosue/Ansible-Playbook-Fedora-Workstation.git
cd Ansible-Playbook-Fedora-Workstation
```

3. **Run the automated workstation setup**:
```bash
ansible-playbook local.yml --ask-become-pass
```
*(Optional: Want only one part, like `ujust`? Run `ansible-playbook local.yml --tags ujust --ask-become-pass`.)*

4. **Open the Control Center anytime**:
```bash
./launcher.sh
```
*(Tip: Run `./launcher.sh --help` to see quick shortcuts like `--appimages`, `--waydroid`, `--dory`, `--prism`, `--localai`, `--virt-builder`, and `--ujust`.)*

### Customizing Your Setup
Want your AppImages, VMs, or scripts stored in different folders, or prefer Light Mode? Open the **User Configuration** section at the very top of `launcher.sh` and change any value—or override it for a single run:
```bash
APPIMAGES_DIR=/opt/AppImages HIG_APPEARANCE=light ./launcher.sh
```

</details>

---

## License

This project is licensed under the [Mozilla Public License Version 2.0](LICENSE).
