#!/usr/bin/env bash

OUTPUT="all_delay_in_milisec_outbound_internet.csv"

# Write header
echo "file,timestamp,ack_rtt_ms" > "$OUTPUT"

# Function to process a single pcap
process_pcap() {
    local pcap="$1"
    local outfile="${pcap%.pcap}_delay.csv"

    tshark -r "$pcap" -Y "ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16)" \
        -T fields -e frame.time_epoch -e tcp.analysis.ack_rtt \
    | awk -v f="$pcap" 'NF==2 && $2*1000<=1000 {print f "," $1 "," $2*1000}' \
    > "$outfile"
}

export -f process_pcap

# Run in parallel, limit jobs to avoid freezing
parallel -j 2 process_pcap ::: *.pcap

# Merge all results and sort by file + timestamp
cat *_delay.csv | sort -t, -k1,1 -k2,2n >> "$OUTPUT"

# Clean up temporary files
rm *_delay.csv

echo "✅ Done! Results saved in $OUTPUT (sorted by file and timestamp)"
