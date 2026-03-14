#!/usr/bin/env bash
# Live-Netzwerk-Traffic-Monitor

# Automatisches Finden des aktiven Netzwerk-Interfaces (eth0, wlan0, enp...)
INTERFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\S+')

if [ -z "$INTERFACE" ]; then
    echo "Keine aktive Netzwerkverbindung gefunden."
    exit 1
fi

echo "Monitoring Interface: $INTERFACE (Beenden mit Strg+C)"
echo "--------------------------------------------------------"
echo -e "ZEIT\t\tDOWNLOAD\tUPLOAD"

while true; do
    # Erste Messung
    R1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    T1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    sleep 1
    # Zweite Messung nach 1 Sekunde
    R2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    T2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

    # Differenz berechnen (Bytes -> KB)
    RX_SPEED=$(( (R2 - R1) / 1024 ))
    TX_SPEED=$(( (T2 - T1) / 1024 ))

    # Ausgabe (Formatierung)
    TIMESTAMP=$(date '+%H:%M:%S')
    
    # In MB/s umwandeln, falls > 1024 KB
    if [ $RX_SPEED -gt 1024 ]; then
        RX_OUT="$(printf "%.2f" $(echo "$RX_SPEED/1024" | bc -l)) MB/s"
    else
        RX_OUT="$RX_SPEED KB/s"
    fi

    if [ $TX_SPEED -gt 1024 ]; then
        TX_OUT="$(printf "%.2f" $(echo "$TX_SPEED/1024" | bc -l)) MB/s"
    else
        TX_OUT="$TX_SPEED KB/s"
    fi

    echo -e "$TIMESTAMP\t$RX_OUT\t$TX_OUT"
done
