#!/usr/bin/env python3

import argparse
import json
import requests
import logging
import re
import zipfile
import os
import sys

log = logging.getLogger("GithubReleaseDownloader")
log.addHandler(logging.StreamHandler())
log.setLevel(logging.WARNING)

GITHUB_RELEASE_URL = "https://api.github.com/repos/%s/releases/latest"
VALID_JSON_KEYS = ('project_slug', 'match', 'destination', 'api_info_only',
                   'test_match')


def get_release_api_info(slug, session=None):
    s = session if session is not None else requests.session()
    url = GITHUB_RELEASE_URL % slug
    r = s.get(url)
    if r.status_code != 200:
        log.error("Response %d for %s", r.status_code, url)
        raise Exception(f"Failed to get json data for {slug}")

    dat = json.loads(r.content)
    return dat


def get_assets(slug, session=None):
    dat = get_release_api_info(slug, session)
    assets = dat['assets']
    return assets


def get_matching_asset_urls(assets, match=None):
    urls = [i['browser_download_url'] for i in assets]
    if match is None:
        return urls
    return [i for i in urls if re.search(match, i) is not None]


def get_latest_asset_urls(slug, match=None, session=None):
    assets = get_assets(slug, session)

    if not assets:
        raise Exception(f"Release for {slug} has no assets")

    matched_assets = get_matching_asset_urls(assets, match)
    if not matched_assets:
        raise Exception(f"{slug} had no matching assets")

    return matched_assets


def download_media(url, destination=None, session=None):
    """url: url to download from
    destination: file path to save to"""
    log.debug("fetching from %s", url)
    basename = os.path.basename(url)
    if destination is not None:
        if os.path.isdir(destination):
            destination = os.path.join(destination, basename)
    else:
        destination = basename

    # skip download if it already exists
    if os.path.isfile(destination) is True:
        return destination

    os.system(f"curl -L '{url}' -o '{destination}'")
    # s = session if session is not None else requests.session()
    # r = s.get(url, stream=True)
    # with open(destination, 'wb') as f:
    #     for chunk in r.iter_content(chunk_size=1024):
    #         if chunk:
    #             f.write(chunk)

    return destination


def parse_args(arguments):
    parser = argparse.ArgumentParser()
    # parser.add_subparsers(dest="subparser")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-s", "--project-slug",
                       help="Project Slug")
    group.add_argument("-j", "--json", type=os.path.expanduser,
                       help="json file describing a series of "
                       "downloads to perform. Structure must be a "
                       "list of dicts, and dicts must contain only "
                       "values in %s as keys" % str(VALID_JSON_KEYS))
    parser.add_argument("-d", "--destination",
                        type=os.path.expanduser,
                        help="path to save file to. If not "
                        "provided or if provided path is a "
                        "directory, filename is used")
    parser.add_argument("-m", "--match",
                        help="Match string to select a specific asset")
    parser.add_argument("-a", "--api-info-only", default=False,
                        action="store_true",
                        help="Print the api-data for the given "
                        "slug out and return")
    parser.add_argument("-t", "--test-match", default=False,
                        action="store_true")
    parser.add_argument("--debug", action="store_true",
                        default=False,
                        help="Enable debug logging")
    args = parser.parse_args(arguments)
    log.setLevel(logging.DEBUG if args.debug is True
                 else logging.WARNING)
    # if args.json is None and args.project_slug is None:
    #     raise argparse.ArgumentError(args.project_slug,
    #                                  "Either json or slug must be specified")

    return args, parser


def handle_single_slug_arg(project_slug, match=None, destination=None,
                           api_info_only=False, test_match=False):
    if api_info_only is True:
        dat = get_release_api_info(project_slug)
        return json.dumps(dat, indent=2)

    if test_match is True:
        assets = get_assets(project_slug)
        urls = get_matching_asset_urls(assets, match)
        return urls

    filenames = []
    # normal download
    urls = get_latest_asset_urls(project_slug, match)
    for url in urls:
        filenames.append(download_media(url, destination))
    return filenames


def handle_json_file(args):
    with open(args.json, "r") as f:
        dat = json.load(f)
    if (not isinstance(dat, list)) or any(bool(not isinstance(i, dict))
                                          for i in dat) is True:
        raise Exception("Json file must be a list of dicts")

    # strip out invalid args
    valid_kwargs = []
    for i, entry in enumerate(dat):
        valid = True
        for k in entry.keys():
            if k not in VALID_JSON_KEYS:
                log.warning("JSON file entry %d contains a key value %s that "
                            "is invalid", i, k)
                valid = False
                break
        if valid is True:
            valid_kwargs.append(entry)

    if args.destination is not None:
        os.makedirs(args.destination, exist_ok=True)
        for kwargs in valid_kwargs:
            d = kwargs.get('destination')
            d = os.path.join(args.destination, d) if d is not None else args.destination
            kwargs['destination'] = d

    for kwargs in valid_kwargs:
        filenames = handle_single_slug_arg(**kwargs)
        for i in filenames:
            print(i)


if __name__ == "__main__":
    args, parser = parse_args(sys.argv[1:])

    if args.project_slug is not None:
        res = handle_single_slug_arg(args.project_slug,
                                     args.match,
                                     args.destination,
                                     args.api_info_only,
                                     args.test_match)
        if isinstance(res, list):
            for i in res:
                print(i)
        else:
            print(res)

    else:
        handle_json_file(args)

