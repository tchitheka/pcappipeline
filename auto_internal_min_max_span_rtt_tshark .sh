#!/usr/bin/env bash 

#Output CSV file 

OUTPUT="internal_outbound_min_span_max_rtt_stats.csv" 

Write CSV header 

echo "file,time_bin,min_rtt,max_rtt,span" > "$OUTPUT" 

#Loop over all pcap files in current directory 

for pcap in *.pcap; do echo "Processing $pcap ..." 

tshark -r "$pcap" -Y "Y "tcp.analysis.ack_rtt && ip.src==10.30.0.0/16 && (ip.dst==10.30.0.1)"  

-T fields -e frame.time_epoch -e tcp.analysis.ack_rtt 2>/dev/null | awk -v fname="$pcap" '{ t=int($1); r=$2; if(!(t in min) || r<min[t]) min[t]=r; if(!(t in max) || r>max[t]) max[t]=r } END{ for (t in min) printf "%s,%d,%.6f,%.6f,%.6f\n", fname, t, min[t], max[t], max[t]-min[t] }' | sort -t',' -k2,2n >> "$OUTPUT" 
done 

echo "Done! Results written to $OUTPUT" 