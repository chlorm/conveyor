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

import os

downloads_dir = os.path.abspath(
    os.path.join(os.path.expanduser('~'), 'Downloads'))
data_dir = os.path.join(downloads_dir, 'Data')
complete_dir = os.path.join(downloads_dir, 'Complete')
rclone_remote = 'gd'
offload_dir = rclone_remote + ':/offload/'
sorted_dir = rclone_remote + ':/tank/'

# Plex
PLEX_SERVER_ADDRESS = 'http://127.0.0.1:32400'
PLEX_TOKEN = ''
MOUNT_ROOT = '/srv/rclone/tv/'
LIBRARY_NAME = 'Television'
