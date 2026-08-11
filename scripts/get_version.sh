#!/bin/bash
set -eou pipefail

UPSTREAM_OWNER=thanos-io
UPSTREAM_REPO=thanos

curl -s https://api.github.com/repos/"$UPSTREAM_OWNER"/"$UPSTREAM_REPO"/releases/latest \
     | jq -r ".tag_name"
