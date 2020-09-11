#

### 
require 'date'
require 'json'
require 'octokit'
require 'csv'
require_relative 'WebDriver.rb'

##### 変数定義
### 固定値
token = ENV["TOKEN"]
REPO = "yukima77/covid-19-ishikawa-m5stack"
BRANCH = "data"
FORMAT_VERSION="1.0.2"
### URL & pref
URL = "https://www.pref.ishikawa.lg.jp/kansen/documents/170003_ishikawa_covid19_patients.csv"
REFERER = "https://www.pref.ishikawa.lg.jp/kansen/coronakennai.html"
PREF = "Fukui"
JSON_FILE=  "data/covid-19-ishikawa.json"
ENV_FILE = "./env-ishikawa.json"
###
comment = "石川県版JSONファイル"
###
num = 1
person_num = 0
ages = ""
sex = ""
location = ""
job = ""
condition = ""
str = nil
year = 0
month = 0
day = 0
###
covid_hash = Hash.new
###
grep_array = [
  [/：/, ""],
  [/ | |　/, ""],
  [/\( |（ /, "("],
  [/）/, ")"],
  [/）/, ")"],
  [/（/, "("],
  [/０/,"0"],
  [/１/,"1"],
  [/２/,"2"],
  [/３/,"3"],
  [/４/,"4"],
  [/５/,"5"],
  [/６/,"6"],
  [/７/,"7"],
  [/８/,"8"],
  [/９/,"9"]
]

###
driver = WebDriver.new(ENV_FILE)
client = Octokit::Client.new access_token: token
###
status = driver.get(URL, REFERER)
driver.download(URL, REFERER)

###
mod_ary = CSV.parse(File.read(File.basename(URL) ,encoding: 'cp932').encode("UTF-8",:invalid => :replace))
###
mod_ary.each {|array|
  person_num = array[0].to_i.to_s unless array[0].nil? or array[0] == ""
  array.delete_at(0)
  ### 全国地方公共団体コード
  array.delete_at(0)
  ### 都道府県名
  array.delete_at(0)
  ### 市区町村名
  array.delete_at(0)
  unless array[0].nil? or array[0] == ""
    ### 発表日
    /(\d+)\/(\d+)\/(\d+)/ =~ array[0]
      year = $1.to_i
      month = $2.to_i
      day = $3.to_i
  end
  array.delete_at(0)
  ### 居住地
  location = ""
  location = array[0]          if array[0] =~ /市|町/
  array.delete_at(0)
  ### 年代
  ages = array[0][/(.*?)代/,1] if     array[0].include?("代")
  ages = array[0]              unless array[0].include?("代")
  array.delete_at(0)
  ### 性別
  sex = array[0][/(.*?)性/,1]  if array[0] =~ /(.*?)性/
  array.delete_at(0)
  ###
  hash = Hash.new
  ###
  hash["number"] = person_num
  hash["ages"] = ages
  hash["sex"] = sex
  hash["location"] = location
  hash["date"] = "#{year}/#{month}/#{day}"
  hash["job"] = ""
  hash["condition"] = ""
  ###
  covid_hash[person_num] = hash
}
### ソート
tmp_covid_hash = covid_hash
covid_hash = Hash.new
###
tmp_covid_hash.sort_by{|id, value| id.to_i }.reverse.each {|key, value|
  covid_hash[key] = value
}
###
last_access = Time.now
covid_hash["last_access"] = last_access
covid_hash["pref"] = PREF
covid_hash["format-version"] = FORMAT_VERSION
covid_hash["url"] = URL
covid_hash["comment"] = comment
###
if person_num == 0 then
  ### スクレーピング失敗
  result = client.contents(REPO, :path => JSON_FILE, :ref => BRANCH)
  contents = client.get(result[:download_url])
  covid_hash = JSON.parse(contents).to_hash unless contents.nil?
  covid_hash["status"] = "failed"
else
  covid_hash["status"] = "OK"
end
### JSON出力 (不要だが出力しておく)
File.open("../#{JSON_FILE}", "w") {|f| 
  f.puts(covid_hash.to_json)
}
###
exit if ENV['DEBUG'] == "1"
###
result = client.contents(REPO, path: JSON_FILE, query: {ref: BRANCH})
result = client.update_contents(REPO, JSON_FILE, "Updating content at #{last_access}", result[:sha], covid_hash.to_json, :branch => BRANCH, :file => JSON_FILE)
