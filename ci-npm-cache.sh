#!/usr/bin/env bash
# set -eux

if [ ! "${1-}" ]; then
  echo -e "\033[31mRequired parameter missing.\033[0m"
  exit 1
fi

if [ -f "package.json" ]; then
  node -e 'require("./package.json")'
  ret=$?
  if [ $ret != 0 ]; then
    echo -e "\033[31m`package.json` syntax error.\033[0m"
    exit $ret
  fi
else
  echo -e "\033[31m`package.json` missing.\033[0m"
  exit 1
fi

NPM_TOOL=`echo "$1" | cut -d ' ' -f1`

if [ $NPM_TOOL == 'yarn' ]; then
  if [ -f "yarn.lock" ]; then
    NPM_LOCK_FILE="yarn.lock"
  fi
else
  if [ -f "npm-shrinkwrap.json" ]; then
    NPM_LOCK_FILE="npm-shrinkwrap.json"
  elif [ -f "package-lock.json" ]; then
    NPM_LOCK_FILE="package-lock.json"
  fi
fi

if [ ! ${NPM_LOCK_FILE-} ]; then
  NPM_LOCK_FILE="package.json"
fi

NPM_VERSIONS_DIGEST=`md5sum ${NPM_LOCK_FILE} | cut -d ' ' -f1`

if [ ${CI_NVM_CACHE_KEY-} ]; then
  NPM_CACHE_DIR="/tmp/ci-npm-cache/${CI_NVM_CACHE_KEY}/${NPM_VERSIONS_DIGEST}"
else
  NPM_PACKAGE_NAME=`node -p 'require("./package.json").name'`
  NODE_VERSION=`node --version`
  NPM_VERSION=`$NPM_TOOL --version`
  NPM_CACHE_DIR="/tmp/ci-npm-cache/${NPM_PACKAGE_NAME}/node_${NODE_VERSION}/${NPM_TOOL}_v${NPM_VERSION}/${NPM_VERSIONS_DIGEST}"
fi

rm -rf "node_modules"

if [ -d "$NPM_CACHE_DIR/node_modules" ]; then
  echo -e "\033[33mUsing npm cache by $NPM_LOCK_FILE at $NPM_CACHE_DIR\033[0m"

  for f in `ls -A "$NPM_CACHE_DIR"`
  do
    if [ -L "$NPM_CACHE_DIR/$f" ]; then
      rm -rf "$NPM_CACHE_DIR/$f"
    fi
  done
else
  rm -rf "$NPM_CACHE_DIR.tmp"
  mkdir -p "$NPM_CACHE_DIR.tmp/node_modules"
  ln -s "$NPM_CACHE_DIR.tmp/node_modules" "node_modules"

  eval "$@"
  ret=$?

  if [ $ret == 0 ]; then
    if [ `ls "node_modules" | wc -l` != 0 ]; then
      echo -e "\033[33mCreated npm cache by $NPM_LOCK_FILE at $NPM_CACHE_DIR\033[0m"
      rm -rf "node_modules"
      mv "$NPM_CACHE_DIR.tmp" "$NPM_CACHE_DIR"
    else
      rm -rf "$NPM_CACHE_DIR.tmp"
      exit 0
    fi
  else
    rm -rf "$NPM_CACHE_DIR.tmp"
    exit $ret
  fi
fi

for f in `ls *.config.* .*rc .*rc.* package.json`
do
  ln -s "$PWD"/"$f" "$NPM_CACHE_DIR/$f"
done  

ln -s "$NPM_CACHE_DIR/node_modules" "node_modules"

exit 0
