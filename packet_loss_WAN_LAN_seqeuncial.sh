#!/usr/bin/env bash

OUTPUT="packet_loss_wan_lan.csv"
echo "file,stream,type,total_segments,retransmissions,dup_acks,loss_percent" > "$OUTPUT"

for PCAP in *.pcap; do
    echo "Processing $PCAP ..."

    # WAN streams
    wan_streams=$(tshark -r "$PCAP" -Y "tcp && ip.src==10.30.0.0/16 && !(ip.dst==10.30.0.0/16)" -T fields -e tcp.stream | sort -n | uniq)
    for stream in $wan_streams; do
        total=$(tshark -r "$PCAP" -Y "tcp.stream==$stream" -T fields -e frame.number | wc -l)
        retrans=$(tshark -r "$PCAP" -Y "tcp.stream==$stream && tcp.analysis.retransmission" -T fields -e frame.number | wc -l)
        dupacks=$(tshark -r "$PCAP" -Y "tcp.stream==$stream && tcp.analysis.duplicate_ack" -T fields -e frame.number | wc -l)

        loss=0
        if [ "$total" -gt 0 ]; then
            loss=$(echo "scale=6; 100*($retrans + $dupacks)/$total" | bc -l)
        fi
        echo "$PCAP,$stream,WAN,$total,$retrans,$dupacks,$loss" >> "$OUTPUT"
    done

    # LAN streams
    lan_streams=$(tshark -r "$PCAP" -Y "tcp && ip.src==10.30.0.0/16 && ip.dst==10.30.0.1" -T fields -e tcp.stream | sort -n | uniq)
    for stream in $lan_streams; do
        total=$(tshark -r "$PCAP" -Y "tcp.stream==$stream" -T fields -e frame.number | wc -l)
        retrans=$(tshark -r "$PCAP" -Y "tcp.stream==$stream && tcp.analysis.retransmission" -T fields -e frame.number | wc -l)
        dupacks=$(tshark -r "$PCAP" -Y "tcp.stream==$stream && tcp.analysis.duplicate_ack" -T fields -e frame.number | wc -l)

        loss=0
        if [ "$total" -gt 0 ]; then
            loss=$(echo "scale=6; 100*($retrans + $dupacks)/$total" | bc -l)
        fi
        echo "$PCAP,$stream,LAN,$total,$retrans,$dupacks,$loss" >> "$OUTPUT"
    done
done
