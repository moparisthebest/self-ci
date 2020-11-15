#!/bin/bash

set_gitea_github_urls() {
    export GITEA_URL="$(git config --get remote.origin.url | sed 's/\.git$//')"
    export GITHUB_URL="$(echo "$GITEA_URL" | sed -r 's@^https?://[^/]+@https://github.com@')"
}

force_push_current_branch_github() {

    [ "${GITHUB_URL-}" == "" ] && echo 'no $GITHUB_URL specified, not deleting' && return 0

    git push -f "$GITHUB_URL"
    git push -f --tags "$GITHUB_URL"
}

# https://docs.github.com/en/free-pro-team@latest/rest/reference/repos#releases

delete_release_github() {
    tag="$1"
    shift

    [ "${GITHUB_URL-}" == "" ] && echo 'no $GITHUB_URL specified, not deleting' && return 0

    project="$(echo "$GITHUB_URL" | sed -r 's@^https?://[^/]+/@@')"

    # crap way without jq
    #release_id="$(curl -s --netrc -H 'Accept: application/json' "https://api.github.com/repos/${project}/releases/tags/$tag" | grep -o '"id": .*' | head -n1 | grep -o '[0-9]*')"
    release_id="$(curl -s --netrc -H 'Accept: application/json' "https://api.github.com/repos/${project}/releases/tags/$tag" | jq .id)"

    if [ "$release_id" != "" -a "$release_id" != "null" ]
    then
        # delete it
        echo "deleting github release_id: $release_id"
        curl -s --netrc -X DELETE "https://api.github.com/repos/${project}/releases/${release_id}"
    fi
}

release_github() {
    tag="$1"
    shift
    file="$1"
    shift
    type="$1"
    shift
    asset_name="$1"
    shift

    [ "${GITHUB_URL-}" == "" ] && echo 'no $GITHUB_URL specified, not releasing' && return 0

    project="$(echo "$GITHUB_URL" | sed -r 's@^https?://[^/]+/@@')"

    # create release
    curl -s -X POST --netrc -H 'Content-Type: application/json' -H 'Accept: application/json' -d "{\"tag_name\":\"$tag\"}" "https://api.github.com/repos/${project}/releases"

    # crap way without jq
    #release_id="$(curl -s --netrc -H 'Accept: application/json' "https://api.github.com/repos/${project}/releases/tags/$tag" | grep -o '"id": .*' | head -n1 | grep -o '[0-9]*')"
    release_id="$(curl -s --netrc -H 'Accept: application/json' "https://api.github.com/repos/${project}/releases/tags/$tag" | jq .id)"

    echo "uploading file to github release_id: $release_id"

    [ "$asset_name" == "" ] && asset_name="$(basename "$file")"

    curl -s --netrc "https://uploads.github.com/repos/${project}/releases/${release_id}/assets?name=$asset_name" -H "Content-Type: $type" --upload-file "$file"
}

delete_release_gitea() {
    tag="$1"
    shift

    [ "${GITEA_URL-}" == "" ] && echo 'no $GITEA_URL specified, not deleting' && return 0

    project="$(echo "$GITEA_URL" | sed -r 's@^https?://[^/]+/@@')"
    host="$(echo "$GITEA_URL" | sed -r -e 's@^https?://@@' -e 's@/.*@@')"

    # they appear to have removed a way to find releases by tag name...
    #curl -v --netrc -H 'Accept: application/json' "https://$host/api/v1/repos/$project/releases/tags/$tag" >/dev/null

    # list all releases, find the id of the one we want
    release_id="$(curl -s --netrc -H 'Accept: application/json' "https://$host/api/v1/repos/$project/releases" | jq ".[] | select(.tag_name == \"$tag\") | .id")"

    if [ "$release_id" != "" -a "$release_id" != "null" ]
    then
        # delete it
        echo "deleting gitea release_id: $release_id"
        curl -s --netrc -H 'Accept: application/json' -X DELETE "https://$host/api/v1/repos/$project/releases/${release_id}"
    fi

}

release_gitea() {
    tag="$1"
    shift
    file="$1"
    shift
    type="$1"
    shift
    asset_name="$1"
    shift

    [ "${GITEA_URL-}" == "" ] && echo 'no $GITEA_URL specified, not releasing' && return 0

    project="$(echo "$GITEA_URL" | sed -r 's@^https?://[^/]+/@@')"
    host="$(echo "$GITEA_URL" | sed -r -e 's@^https?://@@' -e 's@/.*@@')"

    # create release if it doesn't exist
    curl -s --netrc "https://$host/api/v1/repos/$project/releases" -H  "accept: application/json" -H "Content-Type: application/json" -d "{\"draft\": false,  \"prerelease\": false,  \"tag_name\": \"$tag\",  \"target_commitish\": \"$(git rev-parse --verify HEAD)\"}"

    # they appear to have removed a way to find releases by tag name...
    #curl -v --netrc -H 'Accept: application/json' "https://$host/api/v1/repos/$project/releases/tags/$tag" >/dev/null

    # list all releases, find the id of the one we want
    release_id="$(curl -s --netrc -H 'Accept: application/json' "https://$host/api/v1/repos/$project/releases" | jq ".[] | select(.tag_name == \"$tag\") | .id")"

    echo "uploading file to gitea release_id: $release_id"

    [ "$asset_name" == "" ] && asset_name="$(basename "$file")"

    curl -s --netrc "https://$host/api/v1/repos/$project/releases/${release_id}/assets?name=$asset_name" -F "attachment=@$file;type=$type"
}

delete_release_for_all_tags() {
    for tag in $(git tag -l --points-at HEAD)
    do
        delete_release_github "$tag"
        delete_release_gitea "$tag"
    done
    return 0
}

release_for_all_tags() {
    echo 'all tags:'
    git tag -l --points-at HEAD
    for tag in $(git tag -l --points-at HEAD)
    do
        release_github "$tag" "$@"
        release_gitea "$tag" "$@"
    done
    return 0
}

standard_single_release() {
    set_gitea_github_urls
    force_push_current_branch_github
    delete_release_for_all_tags
    release_for_all_tags "$@"
}

standard_pre_release() {
    set_gitea_github_urls
    force_push_current_branch_github
    delete_release_for_all_tags
}

standard_multi_release() {
    set_gitea_github_urls
    release_for_all_tags "$@"
}

if [ $# -ne 0 ]
then
    "$@"
fi
