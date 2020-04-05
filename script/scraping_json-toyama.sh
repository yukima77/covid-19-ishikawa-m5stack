#!/bin/bash

###
source ./.token.env
###
fname=`basename $0`
fname_wo_ext=${fname%.*}
###
bundle exec ruby ${fname_wo_ext}.rb
