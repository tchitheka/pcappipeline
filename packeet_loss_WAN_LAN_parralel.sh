#!/usr/bin/env bash

OUTPUT="packet_loss_wan_lan.csv"
echo "file,stream,type,total_segments,retransmissions,dup_acks,loss_percent" > "$OUTPUT"

process_pcap() {
    PCAP="$1"
    TMP="${PCAP%.pcap}_loss.csv"

    echo "Processing $PCAP ..." >&2
    echo "file,stream,type,total_segments,retransmissions,dup_acks,loss_percent" > "$TMP"

    # WAN streams
    wan_streams=$(tshark -r "$PCAP" -Y "tcp && ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16)" \
                  -T fields -e tcp.stream | sort -n | uniq)

    for stream in $wan_streams; do
        total=$(tshark -r "$PCAP" -Y "tcp.stream==$stream" -T fields -e frame.number | wc -l)
        retrans=$(tshark -r "$PCAP" -Y "tcp.stream==$stream && tcp.analysis.retransmission" -T fields -e frame.number | wc -l)
        dupacks=$(tshark -r "$PCAP" -Y "tcp.stream==$stream && tcp.analysis.duplicate_ack" -T fields -e frame.number | wc -l)
        loss=0
        if [ "$total" -gt 0 ]; then
            loss=$(echo "scale=6; 100*($retrans + $dupacks)/$total" | bc -l)
        fi
        echo "$PCAP,$stream,WAN,$total,$retrans,$dupacks,$loss" >> "$TMP"
    done

    # LAN streams
    lan_streams=$(tshark -r "$PCAP" -Y "tcp && ip.src==10.30.0.0/16 && ip.dst==10.30.0.1" \
                  -T fields -e tcp.stream | sort -n | uniq)

    for stream in $lan_streams; do
        total=$(tshark -r "$PCAP" -Y "tcp.stream==$stream" -T fields -e frame.number | wc -l)
        retrans=$(tshark -r "$PCAP" -Y "tcp.stream==$stream && tcp.analysis.retransmission" -T fields -e frame.number | wc -l)
        dupacks=$(tshark -r "$PCAP" -Y "tcp.stream==$stream && tcp.analysis.duplicate_ack" -T fields -e frame.number | wc -l)
        loss=0
        if [ "$total" -gt 0 ]; then
            loss=$(echo "scale=6; 100*($retrans + $dupacks)/$total" | bc -l)
        fi
        echo "$PCAP,$stream,LAN,$total,$retrans,$dupacks,$loss" >> "$TMP"
    done
}

export -f process_pcap

# Run in parallel (default: nproc jobs)
ls *.pcap | parallel process_pcap {4}

# Merge results
cat *_loss.csv | grep -v "^file" >> "$OUTPUT"
rm *_loss.csv
