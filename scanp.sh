#!/bin/bash

function helpPrint(){

    echo -e "\nUse: sudo $0 -u/-t/-s <target>\n\n"
    echo -e "Arguments for the script: \n"

    echo -e "\t-i > Show mroe detailed port information"
    echo -e "\t-f > Show more detailed port information within a file\n"
    echo -e "\t-t > Scan TCP ports"
    echo -e "\t-u > Scan UDP ports"
    echo -e "\t-s > Scan SCTP ports\n"

	exit 0
}

function extractPorts() { # Func base from S4vitar (Thx S4vitar <3)
    local input_file="$1"
    local output_file="$2"

    ports="$(cat "$input_file" | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    ip_address="$(cat "$input_file" | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"

    echo -e "\n[*] Extracting information...\n" > "$output_file"
    echo -e "\t[*] IP Address: $ip_address" >> "$output_file"
    echo -e "\t[*] Open ports: $ports\n" >> "$output_file"

    echo "$ports" | tr -d '\n' | xclip -sel clip
    echo -e "[*] Ports copied to clipboard\n" >> "$output_file"

    /bin/batcat --paging=never "$output_file" -l c || /bin/cat "$output_file"
    rm "$output_file"
    rm "$input_file"
}

if [ $# -lt 2 ]; then
	helpPrint
	exit 1
fi

target=$2

function TPCscan(){
	nmap --open -sS --min-rate 5000 -p- -n -Pn $target -oG tcpPorts &>/dev/null || exit 1 || echo -e "\nUse: sudo $0 -u/-t/-s <target>\n"
	extractPorts ./tcpPorts tcpPorts.tmp
}

function UDPscan(){
    nmap --open -sU --min-rate 5000 -p- -n -Pn $target -oG udpPorts &>/dev/null || exit 1 || echo -e "\nUse: sudo $0 -u/-t/-s <target>\n"
	extractPorts ./udpPorts updPorts.tmp
}

function SCTPscan(){
    nmap --open -sY --min-rate 5000 -p- -n -Pn $target -oG sctpPorts &>/dev/null || exit 1 || echo -e "\nUse: sudo $0 -u/-t/-s <target>\n"
	extractPorts ./sctpPorts sctpPorts.tmp
}

function getInfo() {
	xclip -o -selection clipboard > ./tmpFile
    ports=$(/bin/cat ./tmpFile)

	nmap -sCV -A -p$ports $target -oG infoPorts &>/dev/null

	rm ./tmpFile &>/dev/null
	/bin/batcat ./infoPorts -l java && rm infoPorts &>/dev/null || cat infoPorts && rm infoPorts &>/dev/null
}

function getInfoInFile() {
    xclip -o -selection clipboard > ./tmpFile
    ports=$(/bin/cat ./tmpFile)

    nmap -sCV -A -p$ports $target -oG infoPorts &>/dev/null

    rm ./tmpFile &>/dev/null
    /bin/batcat ./infoPorts -l java || cat infoPorts
}

while getopts "s:t:u:hif" flag
do
    case "${flag}" in
        t) TPCscan "${OPTARG}" ;;
        u) UDPscan "${OPTARG}" ;;
        s) SCTPscan "${OPTARG}" ;;
        i)
        	getInfo
        ;;

		f)
			getInfoInFile
		;;

        h) helpPrint ;;

        *) helpPrint >&2
            exit 1
            ;;
    esac
done
