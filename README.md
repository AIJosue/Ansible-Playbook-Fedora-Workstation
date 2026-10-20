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

### 2. Update System

Upgrades all installed packages to their **latest versions** using `dnf`.

### 3. Install DNF Packages

Removes unwanted default packages (KDE PIM suite, LibreOffice, Dragon, KCalc, KWrite, NeoChat, Okular, Toolbox, Blender) and installs a curated set via `Scripts/packages.sh`, including:

- **Browsers & AI** — Google Chrome, Microsoft Edge, Pinokio (latest RPM, auto-fetched from GitHub releases)
- **Development Tools** — Git LFS, GitHub CLI (`gh`), Godot, Nix, Clang, CMake, Node.js, `@development-tools` group, Ansible collections
- **Virtualization** — Vagrant, libguestfs, Cockpit, QEMU, Podman, Virt-Manager
- **Utilities** — 7zip, BleachBit, Btrfs Assistant, fastfetch, fish shell, zsh, GNOME Disk Utility
- **Security** — Fail2Ban
- **Networking** — WireGuard, Ncat
- **Communication** — Zoom
- **KDE Apps & Themes** — Kate, Krusader, Dolphin plugins, sound themes, icon themes, Kvantum, GTK/KDE themes, SDDM themes, Plasma addons & applets, Aurorae, and more

### 4. Install Snap Packages

Creates the `/snap` symlink and installs applications via Snap:

- **Standard** — Audacity, Bitwarden, Chromium, CUPS, DigiKam, Firefox, FreeCAD, GIMP, GNOME Characters, Inkscape, K3B, KGet, Node-RED, NordVPN, OBS Studio, OpenVINO AI Plugins for GIMP, Postman, Proton VPN, Snap Store, Steam, Tailscale, Telegram, Termius
- **Classic** — Antigravity, Blender, VS Code, Flutter, PowerShell

### 5. Enable System Services & Firewall

Starts and enables key services and sockets:

- **Services** — `libvirtd`, `fail2ban`, `nix-daemon`, `sshd`, `tailscaled`
- **Sockets** — `podman.socket`, `cockpit.socket`, `snapd.socket`
- **Docker compatibility** — `/var/run/docker.sock` symlink pointing to the Podman socket
- **Firewalld** — enabled with permanent rules for `ssh`, `cockpit`, and `kdeconnect`

### 6. Install Flatpaks

Adds the **Flathub** and **Fedora** Flatpak repositories, then installs a wide selection of applications including:

- **Browsers** — Brave Browser
- **Productivity** — Collabora Office, XMind, Anki, Anytype, Ente Auth, Merkuro Calendar, KDE Itinerary, Tellico, Francis
- **Media** — Kdenlive, HandBrake, Kodi, Haruna, Glaxnimate, Kid3, KST, LabPlot, Clementine (Fedora repo)
- **Photo & Creative** — Krita, RapidRAW, DigiKam (Digikam), Snapshot, Neothesia
- **Gaming** — Heroic Games Launcher (via Bottles), Lutris, Sober (Roblox), Steam (Sober)
- **Utilities** — LocalSend, PeaZip, Cryptomator (via Bottles), KeePassXC, PikaBackup, Warehouse, GearLever, Podman Desktop, Evince, Firmware Updater, GNOME Maps, GNOME Weather, Icon Library, MetadataCleaner, EasyEffects, JDSP4Linux, Crow Translate, DistroShelf, Moonlight, fcast Receiver, Nicotine+, qBittorrent, Cantor, Drawy, Kodaskanna, Kalk, Kalm
- **Fedora repo** — Evolution, Meld, ROcs

### 7. Configure Users and Groups

Creates user profiles with appropriate group memberships:

| User    | Groups |
|---------|--------|
| `<sudo user>` | `wheel`, `libvirt`, `lxd`, `nordvpn`, `render`, `video` |
| `admin` | `wheel`, `libvirt`, `nordvpn`, `render`, `video` |
| `user`  | `libvirt`, `render`, `video` |

Also ensures `~/Desktop` exists for each user account.

#### Interactive User Environment Setup Script

To preserve clean separation between system and user configuration, an interactive utility (`setup-user-environment.sh`) and a `.desktop` launcher are deployed directly to each user's `~/Desktop`. The script supports both interactive menu and CLI flags (`--brew`, `--pixi`, `--terminal`, `--all`):

- **Homebrew Shell Environment** — Detects or installs Homebrew and sources `/home/linuxbrew/.linuxbrew/bin/brew` in `~/.bashrc` / `~/.zshrc`.
- **Pixi Package Manager** — Installs Pixi via the official installer and exports `~/.pixi/bin` to `$PATH` in both shell configs.
- **TLDR & Terminal Utilities** — Updates `tldr` cheatsheet cache, builds Bat syntax caches, configures Git LFS user hooks, and refreshes font and man-page caches.
- **All-in-One Option** — Runs all three steps in sequence.

### 8. Initialize System

- Sets the system **hostname**
- Ensures `~/AppImages` directory exists for the invoking user
- Activates and autostarts the **libvirt** default virtual network
- Defines virtual machine configurations from `VMs/*.xml` via `virsh`

### 9. Install Homebrew

Installs [Homebrew](https://brew.sh/) (Linuxbrew) and configures the system-wide shell environment via `/etc/profile.d/homebrew.sh` and the user's `.bashrc` so `brew` is automatically in `$PATH`.

---

## Project Structure

```
Ansible-Playbook-Fedora-Workstation/
├── local.yml                      # Main playbook entry point
├── tasks/
│   ├── repositories.yml           # Third-party repo configuration
│   ├── update.yml                 # System update
│   ├── packages.yml               # DNF package management + Pinokio RPM
│   ├── snaps.yml                  # Snap package installation
│   ├── services.yml               # Systemd service/socket enablement + firewall
│   ├── flatpaks.yml               # Flatpak setup and installation
│   ├── users-groups.yml           # User creation, groups, and desktop setup
│   ├── initialize.yml             # Hostname, AppImages dir, libvirt network, VMs
│   └── homebrew.yml               # Homebrew installation and PATH configuration
├── Scripts/
│   ├── packages.sh                # DNF package installation script
│   └── setup-user-environment.sh  # Interactive user post-install setup utility
├── Vagrant/
│   └── Vagrantfile                # Vagrant environment definition
├── VMs/                           # Virtual machine XML definitions
│   ├── Android.xml
│   ├── Linux.xml
│   └── Windows.xml
├── logs/                          # Log output directory
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
- **Adding repositories** in `tasks/repositories.yml` (Hashicorp entries are included but commented out)

---

## Final Thought

Automation isn't just about saving time — it's about **building reliable, documented processes**.  
If someone else can clone this repo and get a fully working workstation with a single command,  
then this playbook is doing its job.
