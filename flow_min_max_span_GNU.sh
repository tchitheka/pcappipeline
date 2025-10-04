#!/usr/bin/env bash

OUTPUT="all_rtts.csv"
TMPDIR="./tmp_rtt"

mkdir -p "$TMPDIR"
echo "file,stream,timestamp,rtt_ms" > "$OUTPUT"

# Function to process one pcap
process_pcap() {
    local pcap="$1"
    local outfile="$TMPDIR/$(basename "${pcap%.pcap}").csv"

    tshark -r "$pcap" \
        -Y "tcp.analysis.ack_rtt && ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16)" \
        -T fields -e tcp.stream -e frame.time_epoch -e tcp.analysis.ack_rtt \
    | awk -v f="$(basename "$pcap")" '{print f","$1","$2","$3*1000}' > "$outfile"
}

export -f process_pcap
export TMPDIR

# Run in parallel, max 4 jobs at a time
ls *.pcap | parallel -j 4 process_pcap {}

# Merge into single CSV
cat "$TMPDIR"/*.csv >> "$OUTPUT"

# Optional cleanup
rm -r "$TMPDIR"

echo "✅ Finished. Results saved to $OUTPUT"
