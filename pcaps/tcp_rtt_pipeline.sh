#!/usr/bin/env bash

#process all pcap files in the directory with argus
for file in *.pcap; do
    # Extract the filename without extension
    base="${file%.pcap}"

    # Run argus and save output as .argus
    echo "Processing $file -> ${base}.argus"
    argus -r "$file" -w "${base}.argus"
done