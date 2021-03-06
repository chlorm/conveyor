# Copyright (c) 2017-2018, Cody Opel <codyopel@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import subprocess
from typing import List


# FIXME: make recursion optional
def lsd(root: str) -> List[str]:
    cmd = rclone_args + ['lsf', '--dirs-only', root]
    dirs_raw = subprocess.check_output(cmd).splitlines()
    dirs = []
    for i in dirs_raw:
        dirs.append(i.decode())
    return dirs


# FIXME: make recursion optional
def lsf(root: str) -> List[str]:
    cmd = rclone_args + ['lsf', '-R', '--files-only', root]
    files_raw = subprocess.check_output(cmd).splitlines()
    files = []
    for i in files_raw:
        files.append(i.decode())
    return files


def move(source_file: str, destination_path: str) -> None:
    cmd = rclone_args + [
        'move', '--delete-empty-src-dirs', source_file, destination_path
    ]
    move = subprocess.Popen(cmd)
    move.wait()


def rmdirs(root: str) -> None:
    cmd = rclone_args + ['rmdirs', root]
    rmdirs = subprocess.Popen(cmd)
    rmdirs.wait()


def dedupe(root: str) -> None:
    cmd = rclone_args + ['dedupe', '--dedupe-mode', 'skip', root]
    dedupe = subprocess.Popen(cmd)
    dedupe.wait()


rclone_args = [
    'rclone', '-vv', '--stats', '5s', '--low-level-retries', '20',
    '--tpslimit', '1', '--tpslimit-burst', '4', '--transfers', '1',
    '--checksum', '--immutable'
]
