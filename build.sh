#!/bin/bash

OUTPUT_FILE="🐱collectionhelper.ipf"

rm "$OUTPUT_FILE"
ipf.py --enable-encryption -cvf "$OUTPUT_FILE" src
