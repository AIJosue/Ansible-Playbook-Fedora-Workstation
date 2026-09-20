#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: github_release_asset
short_description: Download and manage release assets from GitHub idempotently
description:
  - Queries the latest release of a GitHub repository and downloads an asset matching a regex pattern.
  - Ensures the downloaded asset is placed at the specified destination with target permissions.
  - Strictly idempotent: does not re-download if the destination file already exists (unless force is true).
options:
  repo:
    description:
      - GitHub repository in the format "owner/repo" (e.g. "darktable-org/darktable").
    type: str
    required: true
  pattern:
    description:
      - Regular expression to match the desired asset filename (e.g. "x86_64.*\\.AppImage").
    type: str
    required: true
  exclude_pattern:
    description:
      - Regular expression for filenames to ignore even if matching pattern.
    type: str
    default: '(\.sig|\.zsync)$'
  dest:
    description:
      - Absolute destination path for the downloaded file.
    type: path
    required: true
  force:
    description:
      - Whether to force re-download even if destination file already exists.
    type: bool
    default: false
  mode:
    description:
      - Permissions of the destination file (e.g. "0755").
    type: raw
    default: "0755"
  owner:
    description:
      - User who should own the file.
    type: str
  group:
    description:
      - Group that should own the file.
    type: str
author:
  - Antigravity Automation Architect
'''

EXAMPLES = r'''
- name: Download latest Darktable AppImage
  github_release_asset:
    repo: darktable-org/darktable
    pattern: 'x86_64.*\.AppImage'
    dest: /home/admin/AppImages/darktable.appimage
    mode: '0755'
'''

RETURN = r'''
dest:
  description: Destination file path.
  returned: always
  type: str
url:
  description: Download URL of the resolved release asset.
  returned: when downloaded
  type: str
asset_name:
  description: Asset filename from GitHub.
  returned: when downloaded
  type: str
'''

import json
import os
import re
import tempfile
import urllib.request
import urllib.error
from ansible.module_utils.basic import AnsibleModule


def fetch_release_info(repo):
    api_url = f"https://api.github.com/repos/{repo}/releases/latest"
    req = urllib.request.Request(
        api_url,
        headers={
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'Ansible-github_release_asset'
        }
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
            return json.loads(data.decode('utf-8')), None
    except urllib.error.HTTPError as e:
        return None, f"HTTP Error {e.code}: {e.reason}"
    except urllib.error.URLError as e:
        return None, f"URL Error: {e.reason}"
    except Exception as e:
        return None, str(e)


def download_asset(url, dest_path):
    req = urllib.request.Request(
        url,
        headers={'User-Agent': 'Ansible-github_release_asset'}
    )
    dest_dir = os.path.dirname(dest_path)
    os.makedirs(dest_dir, exist_ok=True)
    
    with tempfile.NamedTemporaryFile(dir=dest_dir, delete=False) as tmp_file:
        tmp_path = tmp_file.name
        with urllib.request.urlopen(req, timeout=120) as resp:
            while True:
                chunk = resp.read(65536)
                if not chunk:
                    break
                tmp_file.write(chunk)

    os.replace(tmp_path, dest_path)


def main():
    module = AnsibleModule(
        argument_spec=dict(
            repo=dict(type='str', required=True),
            pattern=dict(type='str', required=True),
            exclude_pattern=dict(type='str', default=r'(\.sig|\.zsync)$'),
            dest=dict(type='path', required=True),
            force=dict(type='bool', default=False),
            mode=dict(type='raw', default='0755'),
            owner=dict(type='str', default=None),
            group=dict(type='str', default=None),
        ),
        add_file_common_args=True,
        supports_check_mode=True,
    )

    repo = module.params['repo']
    pattern = module.params['pattern']
    exclude_pattern = module.params['exclude_pattern']
    dest = os.path.expanduser(module.params['dest'])
    force = module.params['force']

    dest_exists = os.path.exists(dest)

    if dest_exists and not force:
        file_args = module.load_file_common_arguments(module.params)
        changed = module.set_fs_attributes_if_different(file_args, False)
        module.exit_json(
            changed=changed,
            dest=dest,
            msg="Asset file already present at destination."
        )

    # Asset needs to be downloaded or checked
    release_data, err = fetch_release_info(repo)
    if err:
        module.fail_json(msg=f"Failed to fetch release info for {repo}: {err}")

    assets = release_data.get('assets', [])
    matched_asset = None
    regex = re.compile(pattern, re.IGNORECASE)
    exclude_regex = re.compile(exclude_pattern, re.IGNORECASE) if exclude_pattern else None

    for asset in assets:
        name = asset.get('name', '')
        if exclude_regex and exclude_regex.search(name):
            continue
        if regex.search(name):
            matched_asset = asset
            break

    if not matched_asset:
        module.fail_json(
            msg=f"No asset in {repo} latest release matched pattern '{pattern}'."
        )

    download_url = matched_asset.get('browser_download_url')
    asset_name = matched_asset.get('name')

    if module.check_mode:
        module.exit_json(
            changed=True,
            dest=dest,
            url=download_url,
            asset_name=asset_name,
            msg=f"Asset {asset_name} would be downloaded to {dest}."
        )

    try:
        download_asset(download_url, dest)
    except Exception as e:
        module.fail_json(msg=f"Failed to download asset from {download_url}: {e}")

    file_args = module.load_file_common_arguments(module.params)
    module.set_fs_attributes_if_different(file_args, False)

    module.exit_json(
        changed=True,
        dest=dest,
        url=download_url,
        asset_name=asset_name,
        msg=f"Asset {asset_name} downloaded successfully to {dest}."
    )


if __name__ == '__main__':
    main()
