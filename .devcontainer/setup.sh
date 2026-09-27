#!/usr/bin/env bash
set -euo pipefail

# Install System packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
    libpq-dev \
    libmariadb-dev \
    libarchive13 \
    libassimp-dev \
    f3d

# JS toolchain
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
corepack enable

# Ruby / JS dependencies
bundle install
yarn install
