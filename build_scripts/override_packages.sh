#!/bin/bash
set -e

#
# build local packages to override the system ones if
# the variable *repoconf_repo_source* is set.
#

repo_dir=`pwd`/'pkg_build'
mkdir -p $repo_dir

if [ -n "${repoconf_repo_source}" ]; then
  git config --global color.ui false
  pushd $repo_dir
  if [ -n "${repoconf_source_branch}" ]; then
    repo init -u $repoconf_repo_source -b $repoconf_source_branch
  else
    repo init -u $repoconf_repo_source
  fi
  repo sync
  # run majic autobuild command to create a pkg repo called foofil
  bash -x ./debian/sync-repo.sh build
  popd
  sbuild -d trusty -A rjil-cicd_2014.2.179ubuntu1.dsc
fi

repo_path=`pwd`
repo_file_name=foofile
repo_full_path="${repo_path}/${repo_file_name}"
temp_url_key=123456789

swift upload package_repo_override $repo_full_path
swift post -m "Temp-URL-Key:${temp_url_key}"
temp_url=`swift tempurl GET 600 /v1/package_repo_override/${repo_file_name} ${temp_url_key}`
object_url=`keystone endpoint-get --service object-store --endpoint-type publicURL | grep object-store.publicURL | head -1 | awk '{gsub(/\/v1/,"");print $4}'`$temp_url

echo $object_url
