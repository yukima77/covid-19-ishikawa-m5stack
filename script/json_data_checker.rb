#

### 
require 'date'
require 'json'
require 'octokit'
require 'csv'
require_relative 'WebDriver.rb'

###
pref_list = [
  "fukui",
  "ishikawa",
  "toyama",
]

###
puts "JSON data checker"
###
pref_list.each {|pref|
  ###
  error_flag = false
  fname = "covid-19-#{pref}.json"
  ###
  covid_hash = nil
  File.open("../data/#{fname}") {|f| 
    covid_hash = JSON.load(f)
  }
  ###
  covid_hash.each {|key,hash|
    error_flag = true if hash["ages"] == ""
    error_flag = true if hash["sex"]  == ""
  }
  puts "Status : NG (#{fname})" if error_flag == true
  puts "Status : OK (#{fname})" if error_flag == false
}
