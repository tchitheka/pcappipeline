#!/usr/bin/env bash

# Default: use current directory
PCAP_DIR="."
OUTPUT="standdev_latency_tuple_tshark.csv"

# Write CSV header
echo "file,src,srcport,dst,dstport,rtt" > "$OUTPUT"

# Function to process one pcap file
process_pcap() {
    local pcap="$1"
    local outfile="${pcap%.pcap}_latency.csv"

    tshark -r "$pcap" \
        -Y "ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16) && tcp.analysis.ack_rtt" \
        -T fields \
        -e ip.src -e tcp.srcport -e ip.dst -e tcp.dstport -e tcp.analysis.ack_rtt \
        2>/dev/null \
    | awk -v f="$(basename "$pcap")" -F'\t' '{print f","$0}' \
    > "$outfile"
}

export -f process_pcap

# Run in parallel, limit jobs for safety
parallel -j 2 process_pcap ::: "$PCAP_DIR"/*.pcap

# Merge results into the final CSV (sorted by file + src + dstport)
cat "$PCAP_DIR"/*_latency.csv | sort -t, -k1,1 -k2,2 -k3,3n -k5,5n >> "$OUTPUT"

# Clean up temporary files
rm "$PCAP_DIR"/*_latency.csv

echo "✅ Done! Results saved to $OUTPUT (sorted by file, src, and ports)"
