# this file is sourced from netbox-cli.init.sh

if ! which json_pp 2>/dev/null >/dev/null; then
	echo "ERROR: missing json_pp" >&2
	echo "Might try: dnf whatprovides '*/json_pp'" >&2
	echo >&2
	echo "(or if you're using non-system perl, try cpanm JSON::PP)" >&2
	echo >&2
	return
fi

# if we have jq installed, use it. otherwise, fall back to boring greyscale
if ! which jq 2>/dev/null >/dev/null; then
	alias jq=json_pp
fi

# set defaults in case it's not defined otherwise
if [[ -z "$__netbox_cache_max_age" ]]; then
	__netbox_cache_max_age=86400 # 1 day
fi

_stat(){
	if stat --version 2>/dev/null >/dev/null; then
		# gnu stat supports --version, bsd/macos stat does not
		stat -c %Y "$@"
	else
		# let's assume if not linux then macos/bsd-like
		stat -f %m "$@"
	fi
}


# main function: this is what we will run on the command line
netbox () {
	subcmd="$1"
	shift

	out=$(mktemp)
	case "$subcmd" in
		get)
			__netbox_get "$@" >"$out"
		;;
		post)
			__netbox_post "$@" >"$out"
		;;
		put)
			__netbox_put "$@" >"$out"
		;;
		patch)
			__netbox_patch "$@" >"$out"
		;;
		delete)
			__netbox_delete "$@" >"$out"
		;;
	esac

	if [[ -t 1 ]]; then
		cat "$out" | jq
	else
		cat "$out" | json_pp
	fi
	rm -f "$out" >/dev/null 2>/dev/null
}

__netbox_build_path () {

	path="$1"
	args="$2"

	if echo "$path" | grep -qF '?'; then
		if [[ ! -z "$args" ]]; then
			echo "Error: cannot include ? in first arg if also including second arg" >&2
			return
		fi
	elif ! echo "$path" | grep -qE '/$'; then
		path="$path/"
	fi

	if [[ -z "$args" ]]; then
		args=""
	elif echo "$args" | grep -qE '^[0-9]+$'; then
		args="$args/"
	else
		args="?$args"
	fi
	echo "https://$__netbox_hostname/api$path$args"
}

__netbox_curl () {
	curl -s -H "Authorization: Token $__netbox_token" -H 'Content-Type: application/json' "$@"
}

__netbox_get () { 
	__netbox_curl -X GET "$( __netbox_build_path "$1" "$2" )"
}

__netbox_post () {
	__netbox_curl -X POST --data-raw "$2" "$( __netbox_build_path "$1" )"
}

__netbox_put () {
	__netbox_curl -X PUT --data-raw "$2" "$( __netbox_build_path "$1" )"
}

__netbox_patch () {
	__netbox_curl -X PATCH --data-raw "$2" "$( __netbox_build_path "$1" )"
}

__netbox_delete () {
	__netbox_curl -X DELETE "$( __netbox_build_path "$1" "$2" )" 
}

function _sed () {
	if which gsed 2>/dev/null; then
		gsed "$@"
	else
		sed "$@"
	fi
}

# rebuild autocomplete file
if [[ ! -e "$__netbox_completion_cache" ]] || [[ ! -s "$__netbox_completion_cache" ]] || [[ $(( $( date +%s ) - $( _stat "$__netbox_completion_cache" ) )) -gt "$__netbox_cache_max_age" ]]; then

	# first, let's make sure we can talk to the API
	# (if the cache is already present, it's reasonable to assume we have API access)
	headers=$(mktemp)
	__netbox_curl -X GET --dump-header "$headers" -o /dev/null "https://$__netbox_hostname/api/"
	status=$( head -1 "$headers" | awk '{ print $2 }' )
	if [[ "$status" != 200 ]]; then
		echo "HTTP request failed -- response headers below:" >&2
		cat "$headers" >&2
		return
	fi
	rm -f "$headers" 2>/dev/null >/dev/null
	unset headers

	# now let's rebuild the cache
	__netbox_get / | json_pp | grep http | cut -d\" -f2 | while read path; do
		__netbox_get /$path/ | json_pp | grep http | _sed -re 's|.*/api/|/|' -e 's|/".*|/|';
	done > "$__netbox_completion_cache"
fi

function __netbox_bash_completion () {

    local cmd="${1##*/}"
    local word=${COMP_WORDS[COMP_CWORD]}
    local line=${COMP_LINE}

	local subcmd=$( echo "$line" | awk '{ print $2 }' )
	local api_path=$( echo "$line" | awk '{ print $3 }' )
	local api_args=$( echo "$line" | awk '{ print $4 }' )

	if [[ "$subcmd" == "$word" ]]; then
		COMPREPLY=($( printf "get\npost\nput\npatch\ndelete\n" | grep -E "^$word" ))
	elif [[ "$api_path" == "$word" ]]; then
		COMPREPLY=($( grep -E "^$word" "$__netbox_completion_cache" ))
	#elif [[ "$api_args" == "$word" ]]; then
	else
		COMPREPLY=()
	fi

}

complete -F __netbox_bash_completion netbox

