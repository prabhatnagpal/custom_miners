#!/usr/bin/env bash

function miner_ver() {
      echo ""
}

function miner_config_echo() {
	miner_echo_config_file "$MINER_DIR/$CUSTOM_MINER/config.txt"
	miner_echo_config_file "$MINER_DIR/$CUSTOM_MINER/epools.txt"
}

function miner_config_gen() {

	local MINER_CONFIG="$MINER_DIR/$CUSTOM_MINER/config.txt"
	mkfile_from_symlink $MINER_CONFIG

	local MINER_EPOOLS="$MINER_DIR/$CUSTOM_MINER/epools.txt"
	mkfile_from_symlink $MINER_EPOOLS

	echo "" > $MINER_CONFIG

	# coin=`echo $META | jq -r '.phoenixminer.coin' | awk '{print tolower($0)}'`
	# grep -q "nicehash" <<< $coin
	# [[ $? -eq 0 || -z ${coin} ]] && coin="auto"
	# [[ ! -z ${coin} ]] && echo "-coin $coin" >> $MINER_CONFIG

	[[ -z $CUSTOM_URL ]] && echo -e "${YELLOW}CUSTOM_URL is empty${NOCOLOR}" && return 1
	echo "Creating epools.txt"
	echo "$CUSTOM_URL" > $MINER_EPOOLS

	if [[ ! -z $CUSTOM_USER_CONFIG ]]; then
		echo "### USER CONFIG ###" >> $MINER_CONFIG
		echo "Appending user config";
		echo "$CUSTOM_USER_CONFIG" >> $MINER_CONFIG
	fi

	echo "-cdmport $CUSTOM_API_PORT" >> $MINER_CONFIG
	echo "-cdm 1" >> $MINER_CONFIG
	echo "-rmode 2" >> $MINER_CONFIG
	echo "-logfile ${CUSTOM_LOG_BASENAME}.log" >> $MINER_CONFIG
	# echo "-allpools 1" >> $MINER_CONFIG
}

miner_config_gen
