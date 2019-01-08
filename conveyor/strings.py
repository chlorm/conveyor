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

# FIXME: rename function to more obvious name
def normalize_string(string):
  # Non-breaking space -> space
  remove_nonbreaking_spaces = re.sub(u'\xC2\xA0',u'\x20', string)
  # FIXME: transliterate here, maybe pyicu?
  #iconv -f utf-8 -t us-ascii//translit
  lower = string.lower()
  replace_colons = re.sub(r':[ ]+', '-', lower)
  simplify_hyphens = re.sub(r'[ \.]+-[ \.]+', '-', replace_colons)
  leading_whitespace = re.sub(r'^[ ]+', '', simplify_hyphens)
  trailing_whitespace = re.sub(r'[ ]+$', '', leading_whitespace)
  ampersand = re.sub(r'&', 'and', trailing_whitespace)
  nonprintable_catchall = re.sub(r'[^a-zA-Z0-9\.\-_ ]+', '', ampersand)
  return(nonprintable_catchall)

def sort_chars(chars, string):
  # FIXME: is this needed?
  # Incase we are sorting previously sorted content guessit doesn't parse correctly.
  conveyor_year_string = re.sub(r'_[1-2][0-9][0-9][0-9]$', '', string)
  # Use a consistent word separator to simplify parsing
  replace_seps_with_spaces = re.sub(r'[\.\-_]+', ' ', conveyor_year_string)
  # FIXME: don't strip Die for english titles
  # FIXME: don't strip LA, e.g. LA to Vegas, this currently doesn't because the A is upper cased.
  # FIXME: add the.a.word as a test case.
  # FIXME: las.vegas
  # FIXME: multiple articles in a row, unlikely, need example if any exist.
  # A, An, Das, Dem, Den, Der, Des, Die, El, La, Las, Le, Les, Lo, Los, Se, The, Un, Una, Unas, Unos
  remove_articles = re.sub(r"^([Aa](|n)|[Dd](as|e[mnrs]|ie)|[Ee]l|[Ll][aeo](|s)|[Ss]e|[Tt]he|[Uu]n(|[ao])(|(?<=[ao])s))\s", '', replace_seps_with_spaces)
  remove_spaces = re.sub(r'[ ]+', '', remove_articles)
  return(remove_spaces[:chars].lower())

def format_title(title):
  return(re.sub('[ ]+', '.', title).lower())
