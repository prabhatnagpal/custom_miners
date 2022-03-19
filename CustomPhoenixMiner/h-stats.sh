#!/usr/bin/env bash

stats_raw=`echo '{"id":0,"jsonrpc":"2.0","method":"miner_getstat2"}' | nc -w $API_TIMEOUT localhost $CUSTOM_API_PORT | jq '.result'`
echo $stats_raw
if [[ $? -ne 0  || -z $stats_raw ]]; then
	echo -e "${YELLOW}Failed to read $miner stats_raw from localhost:${CUSTOM_API_PORT} ${NOCOLOR}"
else
	khs=`echo $stats_raw | jq -r '.[2]' | awk -F';' '{print $1}'`

	local tempfans=`echo $stats_raw | jq -r '.[6]' | tr ';' ' '`
	local temp=()
	local fan=()
	local tfcounter=0
	for tf in $tempfans; do
		(( $tfcounter % 2 == 0 )) &&
			temp+=($tf) ||
			fan+=($tf)
		((tfcounter++))
	done
	temp=`printf '%s\n' "${temp[@]}" | jq --raw-input . | jq --slurp -c .`
	fan=`printf '%s\n' "${fan[@]}" | jq --raw-input . | jq --slurp -c .`

	#local hs=`echo "$stats_raw" | jq -r '.[3]' | tr ';' '\n' | jq -cs '.'`
	local hs=`jq -rc '[ .[3]|split(";")|.[]|if .=="off" then 0 else .|tonumber end ]' <<< $stats_raw`

	local ac=`echo $stats_raw | jq -r '.[2]' | awk -F';' '{print $2}'`
	local rj=`echo $stats_raw | jq -r '.[2]' | awk -F';' '{print $3}'`
	local ir=`echo $stats_raw | jq -r '.[8]' | awk -F';' '{print $1}'`
	local ir_gpu=`echo $stats_raw | jq '.[11]'`
	local ver=`echo $stats_raw | jq -r '.[0]'`
	local algo="ethash"
	if [[ `echo $META | jq -r .custom.coin` == "UBQ" ]]; then
		algo="ubqhash"
	elif [[ `echo $META | jq -r .custom.coin` == "ETC" ]]; then
		algo="etchash"
	fi

	local uptime=`echo "$stats_raw" | jq -r '.[1]' | awk '{print $1*60}'`
	[[ $uptime -lt 60 ]] && head -n 50 $CUSTOM_LOG_BASENAME.log > ${CUSTOM_LOG_BASENAME}_head.log

	local bus_numbers=`jq -rc '[ .[15]|split(";")|.[]|if .=="off" then 0 else .|tonumber end ]' <<< $stats_raw`
        if [[ -z $bus_numbers ]]; then
		local bus_id=""
		local bus_ids=""
		local bus_str=""
		for (( i = 1; i <= `echo $fan | jq length`; i++ )); do
			#2018.12.22:13:38:35.674: main GPU1: GeForce GTX 1050 Ti (pcie 1), CUDA cap. 6.1, 3.9 GB VRAM, 6 CUs
			bus_str=`cat ${CUSTOM_LOG_BASENAME}_head.log | grep "main GPU$i"`
			bus_id=`echo ${bus_str#*" (pcie "} | cut -d \) -f 1`
			bus_ids+=${bus_id}" "
		done
		local bus_numbers=`echo ${bus_ids[@]} | tr " " "\n" | jq -cs '.'`
	fi

	stats=$(jq -n \
		--arg uptime "$uptime" \
		--argjson hs "$hs" --argjson temp "$temp" --argjson fan "$fan" \
		--arg ac "$ac" --arg rj "$rj" --arg ir "$ir" --argjson ir_gpu "$ir_gpu" \
		--arg algo "$algo" \
		--arg ver "$ver" \
		--argjson bus_numbers "$bus_numbers" \
		'{$hs, $temp, $fan, $uptime, $algo, ar: [$ac, $rj, $ir, $ir_gpu], $ver, $bus_numbers}')
fi

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"
