#!/usr/bin/env bash

OUTPUT="throughput_filtered_parallel.csv"

# Write header
echo "file,timestamp,rate_Mbps" > "$OUTPUT"

# Function to process a single pcap
process_pcap() {
    local pcap="$1"
    local outfile="${pcap%.pcap}_rate.csv"
    local BIN=0.1

    tshark -r "$pcap" -Y "ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16)" \
        -T fields -e frame.time_epoch -e frame.len \
    | awk -v f="$pcap" -v bin="$BIN" '
        {
            ts = int($1 / bin) * bin
            bytes[ts] += $2
        }
        END {
            for (t in bytes) {
                rate = bytes[t]*8/1e6/bin
                print f "," t "," rate
            }
        }' > "$outfile"
}

export -f process_pcap

# Process in parallel, limit jobs to avoid freezing
parallel -j 2 process_pcap ::: *.pcap

# Merge all results and sort by file name then timestamp
cat *_rate.csv | sort -t, -k1,1 -k2,2n >> "$OUTPUT"

# Cleanup temporary files
rm *_rate.csv

echo "✅ Done! Results saved in $OUTPUT (sorted by file and timestamp)"