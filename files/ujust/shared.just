# vim: set ft=make :

# Toggle LUKS auto-unlock via TPM2
[group('System')]
toggle-tpm2:
    @/usr/bin/luks-tpm2-autounlock
