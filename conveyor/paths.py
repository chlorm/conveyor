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

import re

import strings

# FIXME: make year optional
# FIXME: validate arguments
# FIXME: match against known titles for corrections
def build_remote_path_television(title, season):
  TitleNml = strings.normalize_string(title)

  Char1 = strings.sort_chars(1, TitleNml)
  Char2 = strings.sort_chars(2, TitleNml)

  TitleFmt = re.sub(r'[ ]+', '.', TitleNml)

  # Pad season 0-9 with a leading zero.
  if season <= 9:
    SeasonPad = '0' + str(season)
  else:
    SeasonPad = str(season)

  return(Char1 + '/' + Char2 + '/' + TitleFmt + '/season' + SeasonPad + '/')
