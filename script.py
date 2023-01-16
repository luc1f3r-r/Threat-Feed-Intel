#!/usr/bin/python3
"""Retrieve last 24 hours of IOCs from TruSTAR and output to a CSV file.
"""

import csv
from datetime import datetime, timedelta, timezone
from typing import List
from trustar2 import TruStar, Observables

__author__ = 'Bradley Logan'
__version__ = '0.90'
__email__ = 'bradley.logan@rhisac.org'

# Override defaults here
ENCLAVE_IDS = [
    "7a33144f-aef3-442b-87d4-dbf70d8afdb0",
]
OUTPUT_FILENAME = None


def obl_dict_to_csv(observables: List[dict],
                    filename: str = None,
                    ) -> None:
    """Take a list of observable dictionaries and write to a CSV file.
    Parameters
    ----------
    observables : List[dict]
        The observables to be written out to a file
    filename : str, optional
        The desired name/path for the output file
    """
    if not filename:
        now = datetime.now().strftime('%Y%m%dT%H%M%S')
        filename = f'rhisac_iocs_last24h_{now}.csv'
    with open(filename, 'w') as f:
        header = list(observables[0].keys())

        # move tags column (if any) to end
        if 'tags' in header:
            header.remove('tags')
            header.append('tags')

        indwriter = csv.writer(f)
        indwriter.writerow(header)
        for observable in observables:
            try:
                row = []
                row.append(observable.get("ioc_value"))
                row.append(observable.get("ioc_indicatorType"))
                if observable.get('ioc_firstSeen') is not None:
                    row.append(datetime.fromtimestamp((observable.get('ioc_firstSeen'))/1000))
                if observable.get('ioc_lastSeen') is not None:
                    row.append(datetime.fromtimestamp((observable.get('ioc_lastSeen'))/1000))

                if observable.get('tags'): # Check to see if tags exist for obl
                    if observable.get('tags') and isinstance(observable['tags'][0], dict):  # tags are dict
                        tags = [t['name'] for t in observable.get('tags', ())]
                    else:  # tags are list of values
                        tags = [t for t in observable.get('tags', ())]
                    row.append("|".join(tags))  # tags in one field, "|" separated
                indwriter.writerow(row)
            except Exception as exc:
                print(f"Error writing indicator {observable} to CSV: {str(exc)}")
    print(f'Wrote {len(observables)} IOCs to CSV file: {filename}')


def retrieve_last24h_obls() -> List[dict]:
    """Query the TruSTAR 2.0 API for last 24 hours of Observables and return them.
    Returns
    _______
    list[dict]
        A list of Observables as dictionaries
    """

    # Instantiate API Object
    try:
        ts = TruStar.config_from_file(config_file_path="/Users/prashantraj/Documents/TruSTAR/TruSTAR-master/trustar.conf", config_role="trustar")
    except KeyError as e:
        print(f'{str(e)[1:-1]} in config file "trustar2.conf". Exiting...')
        exit()

    # Setup to/from times and convert timestamps to milliseconds since epoch
    to_time = datetime.now(timezone.utc)
    from_time = to_time - timedelta(hours=24)  # last 24 hours
    print(f'\nRetrieving all IOCs between UTC {from_time} and {to_time}...')
    from_time = int(from_time.timestamp() * 1000)
    to_time = int(to_time.timestamp() * 1000)

    # Query API for Observables
    # To avoid API limits, query for 1000 Observables at a time
    pages = (
        Observables(ts)
            .set_enclave_ids(ENCLAVE_IDS)
            .set_from(from_time)
            .set_to(to_time)
            .set_page_size(1000)  # Avoid API Limits
            .search()
    )
    obls = [obl for page in pages for obl in page.data]

    # only include most commonly used fields
    out = [
        {
            'ioc_list': obl.value,
            'ioc_indicatorType': obl.type,
            'tags': obl.tags,
            'ioc_firstSeen': obl.first_seen,
            'ioc_lastSeen': obl.last_seen,
            'ioc_value': obl.value,
        } for obl in obls
    ]
    return out


if __name__ == '__main__':
    # Call main function
    obls = retrieve_last24h_obls()

    # Output results, if any, to file
    if not obls:
        print('No IOCs found in last 24h. Nothing to output.')
    else:
        obl_dict_to_csv(obls, OUTPUT_FILENAME)
