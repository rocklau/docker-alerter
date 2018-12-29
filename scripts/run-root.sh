#!/bin/sh
set -o errexit
set -o pipefail
set -o nounset

while true; do
	docker events --filter 'type=container' --filter 'event=stop' --filter 'event=start' --filter 'event=die'  --filter 'event=destory' --format '{{json .}}' |
		while read line; do
			status=$(echo "${line}" | jq .status -r)
			if [[ "${status:0:5}" == "exec_" ]]; then
				continue
			fi
			if [[ "${status}" == "attach" ]]; then
				continue
			fi

			name=$(echo "${line}" | jq .Actor.Attributes.name -r)
			image=$(echo "${line}" | jq .Actor.Attributes.image -r)
			exitCode=$(echo "${line}" | jq .Actor.Attributes.exitCode -r)
			json=$(echo "${line}" | jq '.')

			if [[ "${status}" == "die" ]]; then
				logs="$(curl --silent --show-error --unix-socket /var/run/docker.sock "http:/v1.24/containers/${name}/logs?stdout=1&stderr=1&timestamps=1&since=$(($(date +%s) - 60))")"
			else
				logs=""
			fi

			if [[ "${exitCode}" == "null" ]]; then
				exitCode=""
			else
				exitCode="exitcode ${exitCode}"
			fi

			curl -X POST \
				http://127.0.0.1/hook \
				-H 'Content-Type: application/json' \
				-d @- <<EOF
{
    "title": "${name} ${image}",  
    "description":"Event: ${status} ${exitCode}",  
    "from":"rocky",  
    "touser":"liuyan",
    "url":"https://docker.com" 
}
EOF
		done
done
