#!/usr/bin/env bash
set -eux

NPM_VERSIONS_DIGEST=$CIDER_CI_TREE_ID
NPM_PACKAGE_NAME=`node -p 'require("./package.json").name'`
NPM_CACHE_DIR="/tmp/${NPM_PACKAGE_NAME}_NPM_${CIDER_CI_TREE_ID}/node_modules"

if [ -d "$NPM_CACHE_DIR" ]; then
  echo "NPM module cache exists, just linking..."
else
  echo "NPM modules are yet missing; setting up ..."
  TMP_DIR="${NPM_CACHE_DIR}_${CIDER_CI_TRIAL_ID}"
  mkdir -p "$TMP_DIR"
  ln -s "$TMP_DIR" "node_modules"
  npm install
  rm node_modules
  mv "$TMP_DIR" "$NPM_CACHE_DIR"
fi
ln -s "$NPM_CACHE_DIR" node_modules
