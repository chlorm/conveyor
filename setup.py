#!/usr/bin/env python3

from setuptools import setup

setup(
    name='conveyor',
    version='0.0.0',
    description='Download automation',
    #long_description=,
    author='Cody Opel',
    author_email='cwopel@chlorm.net',
    url='https://github.com/chlorm/conveyor',
    packages=[
      'conveyor'
    ],
    install_requires=[
      'guessit',
      'requests'
    ],
    # TODO: convert scripts to entry_points functions.
    scripts=[
      'bin/conveyor-data-stranded-files',
      'bin/download-complete',
      'bin/offload-complete',
      'bin/offload-sort',
      'bin/update-plex-tv-section-locations'
    ],
    include_package_data=True,
    license='Apache Software License 2.0',
    classifiers=[
      'License :: OSI Approved :: Apache Software License',
      'Programming Language :: Python',
      'Programming Language :: Python :: 3'
    ],
)
