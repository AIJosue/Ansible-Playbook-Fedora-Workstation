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
- **Ansible Core** installed on the system
- **Root privileges** (the playbook uses `become: true`)

Install Ansible and required upstream Galaxy collections:

```bash
sudo dnf install ansible
ansible-galaxy collection install -r requirements.yml
```

---

## Usage

1. Clone this repository:

```bash
git clone https://github.com/ITJosue/Ansible-Playbook-Fedora-Workstation.git
cd Ansible-Playbook-Fedora-Workstation
```

2. Install collection requirements:

```bash
ansible-galaxy collection install -r requirements.yml
```

3. *(Optional)* Edit `local.yml` to customize variables:

```yaml
vars:
  hostname: "Desktop"
  target_user: "{{ ansible_env.SUDO_USER | default(ansible_env.USER) }}"
  xml_dir: "/home/{{ ansible_env.SUDO_USER | default(ansible_env.USER) }}/XMLs"
```

4. Run the playbook locally:

```bash
ansible-playbook local.yml --ask-become-pass
```

---

## What the Playbook Does

The playbook executes the following tasks **in order**:

### 1. Configure Repositories

Adds third-party YUM/DNF repositories declaratively via `ansible.builtin.yum_repository`:

- **Google Chrome**, **Microsoft Edge**, **Microsoft Production**, **Microsoft Teams**, **ProtonVPN**, **Visual Studio Code**, **RPM Fusion Nonfree** (NVIDIA Driver, Steam), **PyCharm COPR**, **Hashicorp**.
- Notifies `refresh dnf cache` handler via decoupled `listen` trigger.

### 2. Enforce Security Posture & Firewall (RHCE Hardening)

Implements enterprise security controls per RHCE system administration standards:
- Sets SELinux to targeted enforcing mode via `ansible.posix.selinux`.
- Ensures `firewalld` is running and permanently permits core services (`ssh`, `cockpit`) via `ansible.posix.firewalld`.
- Hardens SSH daemon (`MaxAuthTries 3`) with configuration syntax pre-validation (`validate: 'sshd -t -f %s'`) and automated backup (`backup: true`).

### 3. Update System

Upgrades all installed packages to their latest versions via `ansible.builtin.dnf`, wrapped in a `block` / `rescue` error containment structure.

### 4. Install DNF Packages

Idempotently removes unwanted default packages and installs the full workstation toolchain wrapped in `block` / `rescue`:

- **Browsers** — Google Chrome, Microsoft Edge
- **Development Tools** — Git LFS, GitHub CLI (`gh`), Godot, Nix, Ollama
- **Virtualization** — Vagrant, libguestfs, Incus, Cockpit, QEMU, Podman
- **Utilities** — 7zip, BleachBit, fastfetch, fish shell, zsh, tmux, strace, uv
- **Security** — Fail2Ban, WireGuard
- **Networking** — ProtonVPN, nmap-ncat
- **KDE Apps** — Kate, Krusader, Dolphin plugins, and more
- **HashiCorp** — Terraform, Terraform LS, Packer, Vagrant, Boundary, Waypoint

### 5. Install Snap Packages

Configures `snapd` and installs applications via `community.general.snap`:

- **Standard** — Bitwarden, Chromium, Firefox, FreeCAD, GIMP, Inkscape, OBS Studio, Postman, Steam, Telegram, Termius, and others
- **Classic** — Blender, VS Code, Flutter, PowerShell

### 6. Enable System Services

Starts and enables system services and sockets via `ansible.builtin.systemd_service`:

- `libvirtd.service`, `fail2ban.service`, `nix-daemon.service`, `sshd.service`
- `podman.socket`, `cockpit.socket`, `snapd.socket`, `incus.socket`

### 7. Install Flatpaks

Configures Flathub and Fedora remotes and installs applications via `community.general.flatpak`:

- **Productivity** — Collabora Office, XMind, Anki, Merkuro, Francis
- **Media** — Kdenlive, HandBrake, Kodi, Haruna, Krita, Clementine
- **Gaming** — Lutris, Sober (Roblox), Moonlight
- **Utilities** — LocalSend, PeaZip, KeePassXC, PikaBackup, Sunshine, Brave Browser

### 8. Configure Users and Groups (Interactive Provisioning)

Prompts interactively for administrator and standard user credentials (`vars_prompt`):
- Masked password input (`private: true`).
- Linux shadow-compatible SHA-512 crypt hashing (`sha512_hash` filter plugin).
- Log protection (`no_log: true`) preventing credential leaks in logs.
- Group assignments (`wheel`, `libvirt`, `incus-admin`, `lxd`, `video`, `render`) via `ansible.builtin.user`.

### 9. Initialize System & Virtualization

- Configures system hostname via `ansible.builtin.hostname`.
- Defines virtual machine domains from `VMs/*.xml` via `community.libvirt.virt`.

### 10. Install AppImages

Downloads and configures AppImages using direct download (`ansible.builtin.get_url`) and latest GitHub release asset resolution (`github_release_asset` native module):

- **Cursor**, **Darktable**, **Jan AI**, **KoboldCPP**, **LMMS**, **MuseScore**, **QtScrcpy**, **DevPod**, **LM Studio**.

### 11. Install CLI Utilities & Configure Shell

- Installs Pixi via `ansible.builtin.unarchive` with `creates` idempotency guard.
- Configures user shell via `ansible.builtin.lineinfile` with strict regex anchoring and automated backup (`backup: true`).
- Manages and updates TLDR pages cache idempotently via bespoke `tldr_cache` module.

---

## Project Structure

```
Ansible-Playbook-Fedora-Workstation/
├── ansible.cfg                # Ansible configuration (library path, filter plugins, inventory)
├── ansible-navigator.yml      # Automation Content Navigator configuration
├── inventory                  # Local target inventory
├── requirements.yml           # Upstream Galaxy collection requirements (version-pinned)
├── local.yml                  # Main playbook entry point
├── filter_plugins/            # Custom Jinja2 filter plugins
│   └── password_filters.py    # Native Linux shadow SHA-512 crypt hasher
├── handlers/                  # Centralized handlers with 'listen' decoupling
│   └── main.yml               # Handlers for systemd, dnf, sshd, and firewalld
├── library/                   # Bespoke native Ansible modules
│   ├── github_release_asset.py # Native GitHub release asset downloader
│   └── tldr_cache.py          # Native idempotent TLDR cache manager
├── vars/                      # Decoupled variable definitions
│   └── main.yml               # Package lists, services, and configuration variables
├── tasks/
│   ├── repositories.yml       # Third-party repo configuration
│   ├── security.yml           # SELinux, firewalld, and SSH hardening (RHCE)
│   ├── update.yml             # System update (block/rescue containment)
│   ├── packages.yml           # DNF package management (block/rescue containment)
│   ├── snaps.yml              # Snap package installation
│   ├── services.yml           # Systemd service enablement
│   ├── flatpaks.yml           # Flatpak setup and installation
│   ├── users-groups.yml       # User creation and interactive credential assignment
│   ├── initialize.yml         # Hostname and libvirt VM definitions
│   ├── appimages.yml          # AppImages download & setup
│   └── utilities.yml          # CLI utilities (Pixi, Fish, TLDR)
├── VMs/                       # Virtual Machine definitions
│   ├── Android.xml
│   ├── Linux.xml
│   └── Windows.xml
├── Vagrant/
│   └── Vagrantfile            # Vagrant environment definition
├── README.md
├── LICENSE
└── travis.yml
```

---

## Architecture & RHCE Compliance

This playbook is built upon **Red Hat Certified Engineer (RHCE)** and **Ansible Core** production standards:
- **Zero Shell / Zero Command**: Zero procedural `shell`, `command`, `raw`, or `script` modules.
- **Flow Control & Error Handling (Chapter 5)**: `block` / `rescue` error boundaries and decoupled `listen` handlers.
- **Configuration & Variable Decoupling (Chapter 4)**: Centralized `vars/main.yml` with pre-flight OS assertions.
- **File Integrity & Safety (Chapter 6)**: Strict mode formatting, automated backups (`backup: true`), and pre-execution syntax validation (`validate`).
- **Security & Least Privilege (Chapter 10)**: Non-root play scope (`become: false`), interactive secret prompts (`vars_prompt`), SHA-512 password crypt, `no_log: true` masking, SELinux enforcement, and firewalld configuration.
- **Navigator Compatibility (Chapter 9)**: Pre-configured for CLI and Automation Content Navigator execution.

