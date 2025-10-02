#!/usr/bin/env bash

# Output CSV file
OUTPUT="all_throughput_in_Mbps_outbound_Internet.csv"

# Write header
echo "file,timestamp,rate_Mbps" > "$OUTPUT"

# Function to process one pcap file
process_pcap() {
    local pcap="$1"
    tshark -r "$pcap" \
        -q -z io,stat,0.1,"SUM(frame.len)frame.len,ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16)" \
        | awk -v f="$pcap" '/^[[:space:]]*[0-9]+\.[0-9]+/ {split($1,a,"-"); print f "," a[1] "," $2*8/1e6}'
}

export -f process_pcap

# Process all pcap files in parallel
ls *.pcap | parallel --halt soon,fail=1 process_pcap {} >> "$OUTPUT"

echo "✅ Done! Results saved in $OUTPUT"
