#!/bin/bash

###
if [ -f ./.token.env ]; then
  source ./.token.env
fi
###
fname=`basename $0`
fname_wo_ext=${fname%.*}
###
bundle exec ruby ${fname_wo_ext}.rb
