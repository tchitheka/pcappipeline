#!/usr/bin/env bash

OUTPUT="all_rtts.csv"

# Write CSV header (overwrite each run)
echo "file,stream,timestamp,rtt_ms,ip.dst,frame.len" > "$OUTPUT"

# Function to process a single pcap
process_pcap() {
    local pcap="$1"
    local tmp_out="${pcap%.pcap}_rtt2.csv"

    tshark -r "$pcap" \
        -Y "ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16) && tcp.analysis.ack_rtt && tcp.analysis.ack_rtt<1" \
        -T fields \
        -e tcp.stream \
        -e frame.time_epoch \
        -e tcp.analysis.ack_rtt \
        -e ip.dst \
        -e frame.len \
        -E header=n -E separator=, -E quote=n \
    | awk -v f="$pcap" -F, '{print f","$1","$2","$3*1000","$4","$5}' > "$tmp_out"

    # Append to global CSV
    cat "$tmp_out" >> "$OUTPUT"
    rm -f "$tmp_out"
}

export -f process_pcap
export OUTPUT

# Run in parallel, max 4 jobs
ls *.pcap | parallel -j6 process_pcap {}
