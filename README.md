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
  hostname: "fedora"       # Change to your desired hostname
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
- **Microsoft Production**
- **Microsoft Teams**
- **ProtonVPN**
- **Visual Studio Code**
- **Zoom**
- **Hashicorp**

### 2. Update System

Upgrades all installed packages to their **latest versions** using `dnf`.

### 3. Install DNF Packages

Removes unwanted default packages (Firefox, LibreOffice, KDE bloat) and installs a curated set including:

- **Browsers** — Google Chrome, Microsoft Edge
- **Development Tools** — Git LFS, GitHub CLI (`gh`), Godot, Nix
- **Virtualization** — Vagrant, libguestfs, Incus, Cockpit, QEMU, Podman
- **Utilities** — 7zip, BleachBit, fastfetch, fish shell, zsh
- **Security** — Fail2Ban
- **Networking** — ProtonVPN
- **Communication** — Zoom
- **KDE Apps** — Kate, Krusader, Dolphin plugins, and more

### 4. Install Snap Packages

Sets up `snapd` and installs applications via Snap:

- **Standard** — Bitwarden, Chromium, GIMP, Inkscape, OBS Studio, Postman, Steam, Telegram, Thunderbird, and others
- **Classic** — Blender, VS Code, Flutter, PowerShell

### 5. Enable System Services

Starts and enables key services:

- `podman.socket`
- `libvirtd.service`
- `fail2ban.service`
- `cockpit.socket`
- `snapd.socket`
- `nix-daemon.socket`

### 6. Install Flatpaks

Adds the **Flathub** and **Fedora** Flatpak repositories, then installs a wide selection of applications including:

- **Productivity** — Collabora Office, GnuCash, XMind, Anki
- **Media** — Kdenlive, HandBrake, Kodi, FreeTube
- **Gaming** — Heroic Games Launcher, Lutris, Steam (Sober)
- **Utilities** — LocalSend, PeaZip, Cryptomator, KeePassXC, PikaBackup

### 7. Initialize System

- Sets the system **hostname**
- Initializes **Incus** and **LXD** container runtimes

### 8. Configure Users and Groups

Creates three user profiles with appropriate group memberships:

| User    | Access Level |
|---------|-------------|
| `admin` | Full sudo/wheel, libvirt, incus-admin, lxd, nordvpn, corectrl |
| `user`  | Standard virtualization and VPN access, no sudo |
| `guest` | No special group access |

### 9. Configure Virtualization

Imports virtual machine definitions from **XML files**, sanitizing UUIDs and MAC addresses before defining them with `virsh`.

### 10. Install Homebrew

Installs [Homebrew](https://brew.sh/) (Linuxbrew) for access to additional packages not available through DNF, Snap, or Flatpak.

---

## Project Structure

```
Ansible-Playbook-Fedora-Workstation/
├── local.yml                  # Main playbook entry point
├── tasks/
│   ├── repositories.yml       # Third-party repo configuration
│   ├── update.yml             # System update
│   ├── packages.yml           # DNF package management
│   ├── snaps.yml              # Snap package installation
│   ├── services.yml           # Systemd service enablement
│   ├── flatpaks.yml           # Flatpak setup and installation
│   ├── initialize.yml         # Hostname and container init
│   ├── users-groups.yml       # User creation and group assignment
│   └── homebrew.yml           # Homebrew installation
├── Scripts/
│   ├── packages.sh            # Script for package setup
│   ├── postinstall.sh         # Script to trigger postinstall directly
│   └── sandbox.sh             # Script for local sandboxing
├── Vagrant/
│   └── Vagrantfile            # Vagrant environment definition
├── VMs/                       # Virtual Machine definitions
│   ├── Android.xml
│   ├── Linux.xml
│   └── Windows.xml
├── logs/                      # Log generation directory
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

