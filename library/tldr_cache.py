#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: tldr_cache
short_description: Manage and update the TLDR pages cache idempotently
description:
  - Ensures that the local TLDR client page cache is initialized and up to date.
  - Operates idempotently by checking cache presence and modification age.
options:
  cache_dir:
    description:
      - Path to the TLDR cache directory. Defaults to ~/.cache/tldr.
    type: path
    required: false
  max_age_days:
    description:
      - Maximum allowed age of the cache in days before triggering an update.
      - Set to 0 to bypass age expiration checks when the cache exists.
    type: int
    default: 14
  state:
    description:
      - Desired cache state.
      - C(present) ensures cache exists and is newer than max_age_days.
      - C(updated) forces a refresh of the cache.
    type: str
    choices: [present, updated]
    default: present
author:
  - Antigravity Automation Architect
'''

EXAMPLES = r'''
- name: Ensure tldr cache is initialized
  tldr_cache:
    state: present

- name: Force update tldr cache
  tldr_cache:
    state: updated
'''

RETURN = r'''
cache_dir:
  description: Path to the resolved tldr cache directory.
  returned: always
  type: str
'''

import os
import time
import zipfile
import io
import urllib.request
from ansible.module_utils.basic import AnsibleModule

PAGES_ZIP_URL = "https://raw.githubusercontent.com/tldr-pages/tldr-pages.github.io/main/assets/tldr.zip"


def is_cache_valid(cache_dir, max_age_days):
    if not os.path.exists(cache_dir) or not os.path.isdir(cache_dir):
        return False

    entries = os.listdir(cache_dir)
    if not entries:
        return False

    if max_age_days > 0:
        stat_info = os.stat(cache_dir)
        age_days = (time.time() - stat_info.st_mtime) / (24 * 3600)
        if age_days > max_age_days:
            return False

    return True


def update_via_python_tldr():
    try:
        import tldr
        tldr.update_cache()
        return True, None
    except Exception as e:
        return False, str(e)


def update_via_download(cache_dir):
    try:
        os.makedirs(cache_dir, exist_ok=True)
        req = urllib.request.Request(
            PAGES_ZIP_URL,
            headers={'User-Agent': 'Ansible-tldr_cache-module'}
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            content = resp.read()

        with zipfile.ZipFile(io.BytesIO(content)) as z:
            z.extractall(cache_dir)

        # Update mtime of cache_dir to current time
        os.utime(cache_dir, None)
        return True, None
    except Exception as e:
        return False, str(e)


def main():
    module = AnsibleModule(
        argument_spec=dict(
            cache_dir=dict(type='path', default=None),
            max_age_days=dict(type='int', default=14),
            state=dict(type='str', default='present', choices=['present', 'updated']),
        ),
        supports_check_mode=True,
    )

    cache_dir = module.params['cache_dir']
    max_age_days = module.params['max_age_days']
    state = module.params['state']

    if not cache_dir:
        cache_dir = os.path.expanduser('~/.cache/tldr')
    else:
        cache_dir = os.path.expanduser(cache_dir)

    valid = is_cache_valid(cache_dir, max_age_days)

    if state == 'present' and valid:
        module.exit_json(
            changed=False,
            cache_dir=cache_dir,
            msg="TLDR cache is present and current."
        )

    if module.check_mode:
        module.exit_json(
            changed=True,
            cache_dir=cache_dir,
            msg="TLDR cache would be updated."
        )

    # Try updating using installed python tldr client first
    success, err = update_via_python_tldr()
    if not success:
        # Fallback to direct download
        success, err = update_via_download(cache_dir)

    if success:
        module.exit_json(
            changed=True,
            cache_dir=cache_dir,
            msg="TLDR cache updated successfully."
        )
    else:
        module.fail_json(
            msg="Failed to update TLDR cache: {0}".format(err),
            cache_dir=cache_dir
        )


if __name__ == '__main__':
    main()
