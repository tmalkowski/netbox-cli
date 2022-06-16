# this file is sourced from netbox-cli.init.sh

# if we have jq installed, use it. otherwise, fall back to json_xs, json_pp, or just plain cat
_jq(){
	if which jq 2>/dev/null >/dev/null; then
		jq
	elif which json_pp 2>/dev/null >/dev/null; then
		json_pp
	elif which json_xs 2>/dev/null >/dev/null; then
		json_xs
	elif which cat 2>/dev/null >/dev/null; then
		cat
	fi
}

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

	case "$subcmd" in
		get)
			__netbox_get "$@"
		;;
		post)
			__netbox_post "$@"
		;;
		put)
			__netbox_put "$@"
		;;
		patch)
			__netbox_patch "$@"
		;;
		delete)
			__netbox_delete "$@"
		;;
	esac | _jq
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
if [[ ! -e "$__netbox_completion_cache" ]] || [[ $(( $( date +%s ) - $( _stat "$__netbox_completion_cache" ) )) -gt 86400 ]]; then


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
	rm -f "$headers"
	unset headers


	netbox get / | _jq | grep http | cut -d\" -f2 | while read path; do
		netbox get /$path/ | grep http | _sed -re 's|.*/api/|/|' -e 's|/".*|/|';
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

