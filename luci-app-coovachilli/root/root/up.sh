#!/bin/sh

TUNTAP=$(basename "$DEV")
UNDO_FILE="/var/run/chilli.$TUNTAP.sh"

. /etc/chilli/functions

[ -e "$UNDO_FILE" ] && sh "$UNDO_FILE" 2>/dev/null
rm -f "$UNDO_FILE" 2>/dev/null

# ipt() {
#     opt=$1; shift
#     echo "iptables -D $*" >> "$UNDO_FILE"
#     iptables "$opt" "$@"
# }
# ipt_in() {
#     ipt -I INPUT -i "$TUNTAP" "$@"
# }

run_up() {
    [ -z "$TUNTAP" ] && return

    if [ -n "$KNAME" ]; then
        [ -n "$DHCPLISTEN" ] && ifconfig "$DHCPIF" "$DHCPLISTEN"
    else
        if [ "$LAYER3" != "1" ]; then
            # Konfigurasi firewall dinonaktifkan
            [ -n "$UAMPORT" ] && [ "$UAMPORT" != "0" ] && :
                # ipt_in -p tcp --dport "$UAMPORT" --dst "$ADDR" -j ACCEPT

            [ -n "$UAMUIPORT" ] && [ "$UAMUIPORT" != "0" ] && :
                # ipt_in -p tcp --dport "$UAMUIPORT" --dst "$ADDR" -j ACCEPT

            [ -n "$HS_TCP_PORTS" ] && for port in $HS_TCP_PORTS; do
                :
                # ipt_in -p tcp --dport "$port" --dst "$ADDR" -j ACCEPT
            done

            [ -n "$HS_UDP_PORTS" ] && for port in $HS_UDP_PORTS; do
                :
                # ipt_in -p udp --dport "$port" --dst "$ADDR" -j ACCEPT
            done

            if [ "$ONLY8021Q" != "1" ]; then
                :
                # ipt -I INPUT -i "$DHCPIF" -j DROP
            fi
        fi

        if [ "$ONLY8021Q" != "1" ]; then
            :
            # ipt -I FORWARD -i "$DHCPIF" -j DROP
            # ipt -I FORWARD -o "$DHCPIF" -j DROP
        fi

        # ipt -I FORWARD -i "$TUNTAP" -j ACCEPT
        # ipt -I FORWARD -o "$TUNTAP" -j ACCEPT

        # ipt -I PREROUTING -t raw -j NOTRACK -i "$DHCPIF"
        # ipt -I OUTPUT -t raw -j NOTRACK -o "$DHCPIF"

        # ipt -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        # ipt -I FORWARD -t mangle -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

        [ "$HS_LAN_ACCESS" != "on" ] && [ "$HS_LAN_ACCESS" != "allow" ] && :
            # ipt -I FORWARD -i "$TUNTAP" ! -o "$HS_WANIF" -j DROP

        # ipt -I FORWARD -i "$TUNTAP" -o "$HS_WANIF" -j ACCEPT

        [ "$HS_LOCAL_DNS" = "on" ] && :
            # ipt -t nat -I PREROUTING -i "$TUNTAP" -p udp --dport 53 -j DNAT --to-destination "$ADDR"
    fi

    [ -e /etc/chilli/ipup.sh ] && . /etc/chilli/ipup.sh
}

FLOCK=$(which flock)
if [ -n "$FLOCK" ] && [ -z "$LOCKED_FILE" ]; then
    export LOCKED_FILE=/tmp/.chilli-flock
    flock -x "$LOCKED_FILE" -c "$0 $@"
else
    run_up
fi
