# Copyright (c) 2018, Cody Opel <codyopel@gmail.com>
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

# Common utils for dealing with hard/symbolic links.

import os


# Updates the source of an existing symlink
def symlink_enforce_target(source, target):
    return


def link_impl(source: str, target: str, symbolic=False, force=False) -> None:
    targetDir = os.path.dirname(target)
    # Create directory scructure
    if not os.path.exists(targetDir):
        try:
            print("creating directory: {}".format(targetDir))
            os.makedirs(targetDir)
        except OSError:
            raise

    if not os.path.exists(target):
        try:
            if symbolic:
                t = "sym"
            else:
                t = "hard"
            print("{}linking: {} => {}".format(t, source, target))
            if symbolic:
                os.symlink(source, target)
            else:
                os.link(source, target)
        except NotImplementedError:
            # raised on python < 3.2 and Windows versions before Vista
            msg = u'Operating system or python version does not support symbolic links.'
            raise FilesystemError(msg, 'link', (source, target),
                                  traceback.format_exc())
        except OSError:
            msg = u'Operating system or filesystem does not support symbolic links.'
            raise FilesystemError(msg, 'link', (source, target),
                                  traceback.format_exc())


def link(source: str, target: str, force=False) -> None:
    link_impl(source, target, force=force)


def symlink(source: str, target: str, force=False) -> None:
    link_impl(source, target, symbolic=True, force=force)
