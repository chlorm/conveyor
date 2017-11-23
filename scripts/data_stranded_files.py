#!/usr/bin/env python3

# List files in Data directory not present in the Complete directory.

import os

home = os.environ['HOME']

def find_files(path):
  f = []
  for i in os.listdir(path):
    if os.path.isfile(os.path.join(path, i)):
      f.append(i)
  return f

completeFiles = find_files(os.path.join(home, 'Downloads', 'Complete'))

for x in sorted(find_files(os.path.join(home, 'Downloads', 'Data'))):
  if x not in completeFiles:
    print(x)
