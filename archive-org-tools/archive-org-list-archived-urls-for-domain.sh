#!/bin/bash

# archive.org list every archived url including subdomains

DOMAIN="example.com"
wget -qO- https://web.archive.org/cdx/search/cdx?url=*.$DOMAIN/*&fl=original,length,timestamp&collapse=digest
