#!/bin/bash
PREFIX="${1:-NOT_SET}"
INTERFACE="$2"
SUBNET="$3"
HOST="$4"
#echo "$@"

##----- проверка root?
if [[ $(id -nu) != "root" ]]
then
    echo "Must be root to run \"$(basename $0)\"."  >&2
    exit 1
fi

##---- Проверка PREFIX
if [[ "$PREFIX" = "NOT_SET" ]]; then
	echo "\$PREFIX must be passed as first positional argument"
	exit 1
elif [[ ! "$PREFIX" =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
        echo "Неправильный префикс!" >&2
        exit 1
fi

##---- Проверка INTERFACE
if [[ -z "$INTERFACE" ]]; then 
	echo "\$INTERFACE must be passed as second positional argument"
	exit 1
elif [[ ! $INTERFACE =~ $(ip -br a | awk '$2=="UP" {print $1}') ]]; then
        echo "\$INTERFACE неверный!"
        exit 1
fi	

##--- Сканирование сети 
if [[ -n "$SUBNET" ]] ; then
        # SUBNET корректная?
        if [[ ! $SUBNET =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]];  then
                echo "\$SUBNET задана некорректно!" >&2
                exit 1
        fi
	if [[ -n $HOST ]] ; then #-- заданы оба и SUBNET и HOST
		# HOST корректный?
		if [[ ! $HOST =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]];  then
			echo "\$HOST задан некорректно!" >&2
			exit 1
		fi
                arping -c 3 -i "$INTERFACE" "${PREFIX}.${SUBNET}.${HOST}" 2> /dev/null
	else			#--- задна только SUBNET а HOST перебираем
	        for HOST in {1..255}
        	do
                	echo "[*] IP : ${PREFIX}.${SUBNET}.${HOST}"
                	arping -c 3 -i "$INTERFACE" "${PREFIX}.${SUBNET}.${HOST}" 2> /dev/null
	        done
	fi
else				#--- SUBNET не задана - перебираем все
	for SUBNET in {1..255}
	do
		for HOST in {1..255}
		do
			echo "[*] IP : ${PREFIX}.${SUBNET}.${HOST}"
			arping -c 3 -i "$INTERFACE" "${PREFIX}.${SUBNET}.${HOST}" 2> /dev/null
		done
	done
fi
