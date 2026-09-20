# 1. Create the admin user and set password
# 'admin' is often reserved by some systems; if this fails, try 'sysadmin'
sudo useradd -m -G wheel admin
echo "admin:123Pass!" | sudo chpasswd

# 2. Update system and install required packages
sudo dnf update -y
sudo dnf install -y ansible git xrdp plasma-workspace-x11 @kde-desktop @virtualization

# 3. Enable and start essential services
sudo systemctl enable --now libvirtd sddm firewalld xrdp
sudo systemctl set-default graphical.target

# 4. Configure X11 for the admin user
# We use sudo to ensure the file is created in the correct home directory
sudo -u admin bash -c 'echo "exec startplasma-x11" > /home/admin/.Xclients'
sudo -u admin chmod +x /home/admin/.Xclients

# 5. Open RDP port on the firewall
sudo firewall-cmd --add-service=rdp --permanent
sudo firewall-cmd --reload
sudo reboot now
