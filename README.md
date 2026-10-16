Changes:
- Added auto removal of blender
- Removed ProtonVPN
- Added auto enable incus and sshd services
- Added KDE customization packages (themes, sounds, applets, kvantum, aurorae, SDDM themes, Plasma addons), clang, cmake, nodejs, btrfs-assistant, gnome-disk-utility, and ansible collections to DNF package installation
- Added Incus container runtime initialization (`incus admin init --minimal`)
- Added automated download and installation of the latest Pinokio RPM from GitHub releases
- Updated Snap packages to match active workstation configuration (removed unused lxd, multipass, anbox; added remmina, cups, proton-vpn, antigravity)
- Added `nordvpn` group to user provisioning, `tailscaled.service` to system services, and automated Homebrew shellenv/PATH configuration
- Added Local AI & LLM acceleration (ROCm RX 6000 GPU override, ollama.service, AppImages directory, render/video user groups)
- Added Container & Virtualization enhancements (Docker socket compatibility symlink, Incus subordinate UID/GID mapping, virt-manager, libvirt default network autostart)
- Added Firewalld service rules for ssh, cockpit (port 9090), and kdeconnect
- Removed `packages-microsoft-com-prod` repository
- Added interactive user post-install setup script (`Scripts/setup-user-environment.sh`) and desktop launcher for on-demand configuration of Homebrew, Pixi, and TLDR/terminal utilities


# Ansible Post-Install Playbook for Fedora

An **Ansible playbook** that automates the post-installation setup of a Fedora workstation.  
Instead of manually installing packages, configuring repositories, and tweaking settings one by one, this playbook handles it all in a single run — saving time and ensuring a **consistent, repeatable** environment.

---

## What Is This Project?

This project is a collection of **Ansible tasks** that provision a fresh Fedora installation into a fully configured development and productivity workstation. It covers everything from adding third-party repositories and installing software, to enabling system services and creating user accounts.

If you've ever spent hours setting up a new machine, *this playbook is designed to eliminate that effort*.

---

## Who Is This For?

- **IT professionals** who need a repeatable workstation setup
- **Developers** looking to quickly bootstrap a Fedora environment
- **Students** learning Ansible and infrastructure automation
- Anyone who wants a **one-command provisioning** workflow

---

## Prerequisites

Before running the playbook, make sure you have:

- A **Fedora** workstation (the playbook uses `dnf` and Fedora-specific repositories)
- **Ansible** installed on the system
- **Root privileges** (the playbook requires `become: true`)

Install Ansible if it's not already present:

```bash
sudo dnf install ansible
```

---

## Usage

1. Clone this repository:

```bash
git clone https://github.com/ITJosue/Ansible-Playbook-Fedora-Workstation.git
cd Ansible-Playbook-Fedora-Workstation
```

2. *(Optional)* Edit `local.yml` to customize the **hostname** and **XML directory** variables:

```yaml
vars:
  hostname: "Desktop"      # Change to your desired hostname
  xml_dir: "$HOME/XMLs"   # Path to VM XML definitions
```

3. Run the playbook locally:

```bash
sudo ansible-playbook local.yml
```

Or run directly from GitHub:

```bash
curl -sSL https://github.com/ITJosue/Ansible-Playbook-Fedora-Workstation/raw/refs/heads/main/postinstall.sh | bash
```

---

## What the Playbook Does

The playbook executes the following tasks **in order**:

### 1. Configure Repositories

Adds third-party YUM/DNF repositories for:

- **Google Chrome**
- **Microsoft Edge**
- **Microsoft Teams**
- **ProtonVPN**
- **Visual Studio Code**
- **Zoom**
- **Hashicorp**

### 2. Update System

Upgrades all installed packages to their **latest versions** using `dnf`.

### 3. Install DNF Packages

Removes unwanted default packages (Firefox, LibreOffice, KDE bloat, Blender) and installs a curated set including:

- **Browsers & AI** — Google Chrome, Microsoft Edge, Pinokio, Ollama
- **Development Tools** — Git LFS, GitHub CLI (`gh`), Godot, Nix, Clang, CMake, Node.js, Ansible collections
- **Virtualization** — Vagrant, libguestfs, Incus, Cockpit, QEMU, Podman, Virt-Manager
- **Utilities** — 7zip, BleachBit, Btrfs Assistant, fastfetch, fish shell, zsh, GNOME Disk Utility
- **Security** — Fail2Ban
- **Networking** — WireGuard, Ncat
- **Communication** — Zoom
- **KDE Apps & Themes** — Kate, Krusader, Dolphin plugins, sound themes, icon themes, Kvantum, GTK/KDE themes, SDDM themes, Plasma addons & applets, Aurorae, and more

### 4. Install Snap Packages

Sets up `snapd` and installs applications via Snap:

- **Standard** — Bitwarden, Chromium, CUPS, GIMP, Inkscape, OBS Studio, Postman, Proton VPN, Remmina, Steam, Tailscale, Telegram, and others
- **Classic** — Antigravity, Blender, VS Code, Flutter, PowerShell

### 5. Enable System Services & Firewall

Starts, enables, and secures key services and sockets:

- `podman.socket` and `/var/run/docker.sock` compatibility symlink
- `libvirtd.service`
- `fail2ban.service`
- `cockpit.socket`
- `snapd.socket`
- `nix-daemon.socket`
- `sshd.service`
- `incus.service` / `incus.socket`
- `tailscaled.service`
- `ollama.service` (Local LLM daemon)
- `firewalld.service` with rules for `ssh`, `cockpit`, and `kdeconnect`

### 6. Install Flatpaks

Adds the **Flathub** and **Fedora** Flatpak repositories, then installs a wide selection of applications including:

- **Productivity** — Collabora Office, GnuCash, XMind, Anki
- **Media** — Kdenlive, HandBrake, Kodi, FreeTube
- **Gaming** — Heroic Games Launcher, Lutris, Steam (Sober)
- **Utilities** — LocalSend, PeaZip, Cryptomator, KeePassXC, PikaBackup

### 7. Initialize System

- Sets the system **hostname**
- Configures ROCm AMD GPU compute override (`HSA_OVERRIDE_GFX_VERSION=10.3.0`)
- Ensures `~/AppImages` directory exists for portable AI and media tools
- Configures subordinate UID/GID mappings in `/etc/subuid` and `/etc/subgid` for unprivileged containers
- Initializes **Incus** container runtime (`incus admin init --minimal`)
- Activates and autostarts the **libvirt** default virtual network
- Defines virtual machine configurations via `virsh`

### 8. Configure Users and Groups

Creates user profiles with appropriate group memberships:

| User    | Access Level |
|---------|-------------|
| `admin` | Full sudo/wheel, libvirt, incus-admin, lxd, nordvpn, render, video, corectrl |
| `user`  | Standard virtualization, GPU compute, and VPN access, no sudo |
| `guest` | No special group access |

#### Interactive User Environment Setup Script

To preserve clean separation and allow users or administrators to decide what gets installed on an account, an interactive utility (`setup-user-environment.sh`) and a desktop launcher (`Setup-User-Environment.desktop`) are deployed directly to the user's `~/Desktop`:
- **Homebrew Shell Environment** — Sources and configures `/home/linuxbrew/.linuxbrew/bin/brew` in `~/.bashrc` / `~/.zshrc`.
- **Pixi Package Manager** — Installs Pixi via `curl -fsSL https://pixi.sh/install.sh | sh` and exports `~/.pixi/bin` to `$PATH`.
- **TLDR & Terminal Utilities** — Updates `tldr` cheatsheet cache (`tldr --update`), builds Bat syntax caches, configures Git LFS user hooks, and refreshes font and man caches.
- **All-in-One Option** — Runs the entire post-install setup in a single step.

### 9. Configure Virtualization

Imports virtual machine definitions from **XML files**, sanitizing UUIDs and MAC addresses before defining them with `virsh`.

### 10. Install Homebrew

Installs [Homebrew](https://brew.sh/) (Linuxbrew) and configures the system-wide shell environment via `/etc/profile.d/homebrew.sh` and user `.bashrc` so `brew` is automatically in `$PATH`.

---

## Project Structure

```
Ansible-Playbook-Fedora-Workstation/
├── local.yml                      # Main playbook entry point
├── tasks/
│   ├── repositories.yml           # Third-party repo configuration
│   ├── update.yml                 # System update
│   ├── packages.yml               # DNF package management
│   ├── snaps.yml                  # Snap package installation
│   ├── services.yml               # Systemd service enablement
│   ├── flatpaks.yml               # Flatpak setup and installation
│   ├── initialize.yml             # Hostname and container init
│   ├── users-groups.yml           # User creation, groups, and desktop setup
│   └── homebrew.yml               # Homebrew installation
├── Scripts/
│   ├── packages.sh                # Script for package setup
│   ├── postinstall.sh             # Script to trigger postinstall directly
│   ├── sandbox.sh                 # Script for local sandboxing
│   └── setup-user-environment.sh  # Interactive user post-install setup utility
├── Vagrant/
│   └── Vagrantfile                # Vagrant environment definition
├── VMs/                           # Virtual Machine definitions
│   ├── Android.xml
│   ├── Linux.xml
│   └── Windows.xml
├── logs/                          # Log generation directory
├── README.md
├── LICENSE
└── travis.yml
```

---

## Customization

This playbook is meant to be **forked and adapted**. Common modifications include:

- **Adding or removing packages** in `tasks/packages.yml`, `tasks/snaps.yml`, or `tasks/flatpaks.yml`
- **Changing the hostname** in `local.yml`
- **Adjusting user accounts** in `tasks/users-groups.yml`
- **Disabling tasks** you don't need by commenting out `include_tasks` lines in `local.yml`

---

## Final Thought

Automation isn't just about saving time — it's about **building reliable, documented processes**.  
If someone else can clone this repo and get a fully working workstation with a single command,  
then this playbook is doing its job.

