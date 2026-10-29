# vim: set ft=make :

# Clean up unused containers, volumes, and flatpak runtimes
clean-system:
    #!/usr/bin/bash
    if gum confirm "Prune unused (dangling) Podman images and volumes?"; then
        echo "Images that would be pruned:"
        /usr/bin/podman image ls --filter dangling=true 2>/dev/null
        echo "Volumes that would be pruned:"
        /usr/bin/podman volume ls --filter dangling=true --quiet 2>/dev/null
        if gum confirm "Proceed with pruning Podman images and volumes?"; then
            /usr/bin/podman image prune -f
            /usr/bin/podman volume prune -f
        fi
    fi

    if command -v docker >/dev/null 2>&1; then
      if gum confirm "Prune unused (dangling) Docker images and volumes?"; then
        echo "Images that would be pruned:"
        docker image ls --filter dangling=true 2>/dev/null
        echo "Volumes that would be pruned:"
        docker volume ls --filter dangling=true --quiet 2>/dev/null
        if gum confirm "Proceed with pruning Docker images and volumes?"; then
            docker image prune -f
            docker volume prune -f
        fi
      fi
    fi

    flatpak uninstall --unused -y
    if command -v dnf5 >/dev/null 2>&1; then
        sudo dnf5 clean all
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf clean all
    elif command -v rpm-ostree >/dev/null 2>&1; then
        rpm-ostree cleanup -bm
    fi
    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        brew autoremove
        brew cleanup
    fi
