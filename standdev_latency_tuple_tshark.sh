#!/usr/bin/env bash

# Default: use current directory
PCAP_DIR="."
OUTPUT="standdev_latency_tuple_tshark.csv"

# Write CSV header
echo "file,src,srcport,dst,dstport,rtt" > "$OUTPUT"

# Loop through all pcap files in current directory
for pcap in "$PCAP_DIR"/*.pcap; do
    echo "Processing $pcap ..."
    tshark -r "$pcap" \
        -Y "ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16) && tcp.analysis.ack_rtt" \
        -T fields \
        -e ip.src -e tcp.srcport -e ip.dst -e tcp.dstport -e tcp.analysis.ack_rtt \
        2>/dev/null | awk -v f="$(basename "$pcap")" -F'\t' '{print f","$0}' >> "$OUTPUT"
done

echo "✅ Done! Results saved to $OUTPUT"
