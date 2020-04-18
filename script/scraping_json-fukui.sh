#!/bin/bash

### 
script_dir=$(cd $(dirname $0); pwd)
cd $script_dir

###
export DEBUG=0

###
if [ -f ./.token.env ]; then
  source ./.token.env
fi
###
fname=`basename $0`
fname_wo_ext=${fname%.*}
###
if [ `echo ${fname} | grep debug` ]; then
  export DEBUG=1
  fname=`echo ${fname} | sed -r 's/^debug-(.*)/\1/'`
  fname_wo_ext=${fname%.*}
fi
###
bundle exec ruby ${fname_wo_ext}.rb
