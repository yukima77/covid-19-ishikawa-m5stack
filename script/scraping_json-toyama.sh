#!/bin/bash

### 
script_dir=$(cd $(dirname $0); pwd)
cd $script_dir

###
if [ -f ./.token.env ]; then
  source ./.token.env
fi
###
fname=`basename $0`
fname_wo_ext=${fname%.*}
###
bundle exec ruby ${fname_wo_ext}.rb
