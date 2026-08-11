#!/bin/bash

org='thanos-io'
proj='thanos'
version_number=10

versions(){
    curl -sL "https://api.github.com/repos/${org}/${proj}/releases" | jq -r ".[].tag_name" | \
        sort -rV | \
        head -n ${version_number}
}

batch_build() {
    local versions_=$(versions)

    for version_ in $versions_; do
        ./scripts/build_in_docker.sh $version_
    done

}

batch_upload() { 

    local versions_=$(versions)

    for version_ in $versions_; do
        gh release view ${version_} > /dev/null 2>&1 || ./scripts/release.sh $version_
    done

}

batch_build
