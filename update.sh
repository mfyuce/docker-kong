#!/usr/bin/env bash
set -e

if ! [ "$1" ]
then
   echo "usage: $0 <version>"
   echo "example: $0 1.2.3"
   exit 1
fi

version=$1

if [[ "$version" =~ "rc" ]]; then
  version="${version//-}"
fi

function red() {
   echo -e "\033[1;31m$@\033[0m"
}

function die() {
   red "*** $@"
   echo "See also: $0 --help"
   echo
   exit 1
}

# get kong url from dockerfile
# and fill it up with needed args
function get_url() {
  dockerfile=$1
  arch=$2
  args=$3

  eval $args

  raw_url=$(grep download.konghq.com $dockerfile | awk -F" " '{print $3}' | sed 's/\"//g')

  # set variables contained in raw url
  KONG_VERSION=$version

  eval echo $raw_url
}

hub --version &> /dev/null || die "hub is not in PATH. Get it from https://github.com/github/hub"

kbt_in_kong_v=$(curl -sL https://raw.githubusercontent.com/Kong/kong/$version/.requirements | grep 'KONG_BUILD_TOOLS_VERSION\=' | awk -F"=" '{print $2}' | tr -d "'[:space:]")
if [[ -n "$kbt_in_kong_v" ]]; then
  sed -i.bak 's/KONG_BUILD_TOOLS?=.*/KONG_BUILD_TOOLS?='$kbt_in_kong_v'/g' Makefile
fi

pushd alpine
   url=$(get_url Dockerfile amd64)
   curl -fL $url -o /tmp/kong
   new_sha=$(sha256sum /tmp/kong | cut -b1-64)

   sed -i.bak 's/ARG KONG_AMD64_SHA=.*/ARG KONG_AMD64_SHA=\"'$new_sha'\"/g' Dockerfile
   sed -i.bak 's/ARG KONG_VERSION=.*/ARG KONG_VERSION='$version'/g' Dockerfile

   url=$(get_url Dockerfile arm64)
   curl -fL $url -o /tmp/kong
   new_sha=$(sha256sum /tmp/kong | cut -b1-64)

   sed -i.bak 's/ARG KONG_ARM64_SHA=.*/ARG KONG_ARM64_SHA=\"'$new_sha'\"/g' Dockerfile
   sed -i.bak 's/ARG KONG_VERSION=.*/ARG KONG_VERSION='$version'/g' Dockerfile
popd

pushd centos
   url=$(get_url Dockerfile amd64)
   curl -fL $url -o /tmp/kong
   new_sha=$(sha256sum /tmp/kong | cut -b1-64)

   sed -i.bak 's/ARG KONG_SHA256=.*/ARG KONG_SHA256=\"'$new_sha'\"/g' Dockerfile
   sed -i.bak 's/ARG KONG_VERSION=.*/ARG KONG_VERSION='$version'/g' Dockerfile
popd

pushd rhel
   url=$(get_url Dockerfile amd64 "RHEL_VERSION=7")
   curl -fL $url -o /tmp/kong
   new_sha=$(sha256sum /tmp/kong | cut -b1-64)

   sed -i.bak 's/ARG KONG_SHA256=.*/ARG KONG_SHA256=\"'$new_sha'\"/g' Dockerfile
   sed -i.bak 's/ARG KONG_VERSION=.*/ARG KONG_VERSION='$version'/g' Dockerfile
popd

pushd ubuntu
   sed -i.bak 's/ARG KONG_VERSION=.*/ARG KONG_VERSION='$version'/g' Dockerfile
popd

echo "****************************************"
git diff
echo "****************************************"

echo "Everything looks all right? (y/n)"
echo "(Answering y will commit, push the branch, and open a browser with the PR)"
read
if ! [ "$REPLY" == "y" ]
then
   exit 1
fi

git commit -av -m "chore(*) bump to Kong $version"
git push --set-upstream origin release/$version

hub pull-request -b master -h "$branch" -m "Release: $version"
