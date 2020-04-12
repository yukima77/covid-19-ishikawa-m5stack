#!/bin/bash

###
script_name=$0
###
if [ $# -ne 1 ]; then
  echo "Usage : ${script_name} <pref>"
  exit 1
fi

### 県名
pref=$1

### 実行ディレクトリに移動
script_dir=$(cd $(dirname ${script_name}); pwd)
cd ${script_dir}
### ruby実行環境設定
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
###
bash convert_json-${pref}.sh
