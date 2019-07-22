from typing import List
from xml.etree import ElementTree

import requests

import config


def section_create(section: str) -> None:
    address = config.PLEX_SERVER_ADDRESS + '/library/sections'
    headers = {
        'X-Plex-Token': config.PLEX_TOKEN,
    }
    params = {
        'name': section,
        'type': 'show',
        'agent': 'com.plexapp.agents.thetvdb',
        'scanner': 'Plex Series Scanner',
        'language': 'en',
        'importFromiTunes': '',
        'enableAutoPhotoTags': '',
        # Specifies an arbitrary default location
        'location': ('/non-existant-path/' + section)
    }
    response = requests.post(address, headers=headers, params=params)


def section_get_key(section: str) -> None:
    address = config.PLEX_SERVER_ADDRESS + '/library/sections/'
    headers = {
        'X-Plex-Token': config.PLEX_TOKEN,
    }
    xml = requests.get(config.PLEX_SERVER_ADDRESS + '/library/sections',
                       headers=headers)
    tree = ElementTree.fromstring(xml.content)
    sectionkey = tree.find("./Directory[@title='" + section +
                           "']").attrib["key"]
    return sectionkey


def section_set_locations(sectionkey: str, paths: List[str]):
    address = config.PLEX_SERVER_ADDRESS + '/library/sections/' + str(
        sectionkey)
    headers = {
        'X-Plex-Token': config.PLEX_TOKEN,
    }
    params = {'agent': 'com.plexapp.agents.thetvdb', 'location': paths}
    response = requests.put(address, headers=headers, params=params)
