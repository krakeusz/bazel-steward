#!/bin/sh
# Editor terminals start here. The account's shell is read from passwd on every
# start because profiles change it after the editor server has already started.
shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
[ -x "${shell}" ] || shell=/bin/bash
SHELL="${shell}"
export SHELL
exec "${shell}" -l
