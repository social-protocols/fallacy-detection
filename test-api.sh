#!/usr/bin/env bash
set -Eeuo pipefail

curl \
	--silent \
	--fail \
	--header "Content-Type: application/json" \
	--data $'{"post": "Comrade Kamala will obliterate Social Security and Medicare by giving it away to the Millions of Illegal Immigrants who are infiltrating our Country!"}' \
	http://127.0.0.1:8080/classify

