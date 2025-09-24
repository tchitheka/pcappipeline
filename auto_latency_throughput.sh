#!/usr/bin/env bash

# Output file
OUTPUT="throughput_latency_bins.csv"
echo "file,bin_start,bin_end,total_bytes,throughput_mbps,avg_rtt_ms,min_rtt_ms,max_rtt_ms,span_rtt_ms" > "$OUTPUT"

# Loop through all .pcap files in current directory
for PCAP in *.pcap; do
    echo "Processing $PCAP ..."

    tshark -r "$PCAP" \
        -Y "tcp.analysis.ack_rtt && ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16)" \
        -T fields -e frame.time_epoch -e frame.len -e tcp.analysis.ack_rtt |
    awk -v file="$PCAP" '
    BEGIN { bin_size=1 }
    {
        time=$1; bytes=$2; rtt=$3
        if (time == "" || bytes == "" || rtt == "") next

        bin=int(time/bin_size)

        # aggregate per bin
        bin_bytes[bin]+=bytes
        bin_rtt_sum[bin]+=rtt*1000     # RTT → ms
        bin_rtt_count[bin]++
        if (bin_rtt_min[bin]==0 || rtt*1000 < bin_rtt_min[bin]) bin_rtt_min[bin]=rtt*1000
        if (rtt*1000 > bin_rtt_max[bin]) bin_rtt_max[bin]=rtt*1000
    }
    END {
        for (b in bin_bytes) {
            avg_rtt = (bin_rtt_count[b] > 0 ? bin_rtt_sum[b]/bin_rtt_count[b] : 0)
            span_rtt = (bin_rtt_max[b] - bin_rtt_min[b])
            throughput_mbps = (bin_bytes[b] * 8) / 1000000.0
            printf("%s,%d,%d,%d,%.6f,%.3f,%.3f,%.3f,%.3f\n", file, b, b+1, bin_bytes[b], throughput_mbps, avg_rtt, bin_rtt_min[b], bin_rtt_max[b], span_rtt)
        }
    }' >> "$OUTPUT"
done

echo "✅ Done. Combined results with throughput (Mbps) saved in $OUTPUT"
