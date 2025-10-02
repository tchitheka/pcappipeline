#!/usr/bin/env bash

OUTPUT="all_throughput_in_Mbps_outbound_internet.csv"
TMPDIR=$(mktemp -d)

# Write header
echo "file,timestamp,rate_Mbps" > "$OUTPUT"

# Function to process a single pcap
process_pcap() {
    local pcap="$1"
    local tmpfile="$TMPDIR/${pcap}.csv"
    BIN=0.1

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
        }' > "$tmpfile"
}

export -f process_pcap
export TMPDIR

# Run all pcaps in parallel
parallel process_pcap ::: *.pcap

# Merge all temporary files into the final CSV
cat "$TMPDIR"/*.csv >> "$OUTPUT"
rm -r "$TMPDIR"

echo "✅ Done! Results saved in $OUTPUT"
