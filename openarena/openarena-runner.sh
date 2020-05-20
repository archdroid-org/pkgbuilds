#!/usr/bin/env bash

file=`basename "$0"`
if [ "$file" == 'openarena' ]; then
  file='openarena'
else
  file='oa_ded'
fi
cd '/opt/openarena'

"./${file}.aarch64" $@