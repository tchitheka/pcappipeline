#!/usr/bin/env bash

# Output CSV file
OUTPUT="all_delay_in_milisec_outbound_internet.csv"

# Write header
#to be merged with throughput / for load delay analysis
echo "file,timestamp,ack_rtt_ms" > "$OUTPUT"

# Function to process a single pcap
process_pcap() {
    local pcap="$1"
    tshark -r "$pcap" -Y "ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16)" \
        -T fields -e frame.time_epoch -e tcp.analysis.ack_rtt \
        | awk -v f="$pcap" 'NF==2 && $2*1000<=1000 {print f "," $1 "," $2*1000}'
}

export -f process_pcap

# Use GNU parallel to process all pcaps in parallel
ls *.pcap | parallel --halt soon,fail=1 process_pcap {} >> "$OUTPUT"

echo "All done! Results saved in $OUTPUT."
