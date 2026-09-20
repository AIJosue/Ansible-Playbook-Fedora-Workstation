#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function
__metaclass__ = type

try:
    import crypt
except ImportError:
    crypt = None


def sha512_hash(password, salt=None):
    """
    Computes a Linux /etc/shadow compatible SHA-512 crypt hash ($6$salt$hash).
    Uses standard library crypt if available, falling back to passlib.
    """
    if not password:
        return ""

    if crypt is not None:
        if not salt:
            salt = crypt.mksalt(crypt.METHOD_SHA512)
        elif not salt.startswith("$6$"):
            salt = f"$6${salt}"
        return crypt.crypt(password, salt)

    try:
        import passlib.hash
        return passlib.hash.sha512_crypt.using(rounds=5000).hash(password)
    except ImportError:
        raise RuntimeError("Neither python crypt nor passlib is available to generate SHA-512 password hash.")


class FilterModule(object):
    """ Custom filter plugins for password hashing """

    def filters(self):
        return {
            'sha512_hash': sha512_hash,
        }
