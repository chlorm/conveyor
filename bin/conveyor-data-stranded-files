#!/usr/bin/env python3

# List files in Data directory not present in the Complete directory.

import os

from conveyor import config

def find_files(path):
  f = []
  for i in os.listdir(path):
    if os.path.isfile(os.path.join(path, i)):
      f.append(i)
  return f

completeFiles = find_files(config.complete_dir)

for x in sorted(find_files(config.data_dir)):
  if x not in completeFiles:
    print(x)
