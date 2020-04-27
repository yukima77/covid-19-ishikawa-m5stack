#

### 
require 'date'
require 'json'
require 'octokit'
require 'roo'
require 'date'
require_relative 'WebDriver.rb'

##### 変数定義
### 固定値
token = ENV["TOKEN"]
REPO = "yukima77/covid-19-ishikawa-m5stack"
BRANCH = "data"
FORMAT_VERSION="1.0.2"
### URL & pref
URL = "http://www.pref.toyama.jp/cms_pfile/00021798/01390407.xlsx"
REFERER = "http://www.pref.toyama.jp/cms_sec/1205/kj00021798.html"
PREF = "Toyama"
JSON_FILE=  "data/covid-19-toyama.json"
ENV_FILE = "./env-toyama.json"
###
comment = "富山県版JSONファイル"
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
doc = driver.get_parsed_content(REFERER)
###
url = ""
doc.xpath("//*[@id='file']/ul/li").each {|item|
  item.css("a").each {|anchor|
    url = anchor[:href] if File.extname(anchor[:href]) == ".xlsx"
  }
}
###
driver.download(url, REFERER)
xlsx = Roo::Spreadsheet.open(File.basename(URL))
xlsx.each_row_streaming { |row|
  str_array = Array.new
  row.each { |item|
    str = ""
    str = item.value unless item.value.nil?
    str_array << str.to_s
  }
  if str_array[0] =~ /^[0-9]+$/ then
    person_num = str_array[0].to_i.to_s unless str_array[0].nil? or str_array[0] == ""
    str_array.delete_at(0)
    ### 市番号
    str_array.delete_at(0)
    ### 検査結果判明日
    date_time = Time.parse('1899/12/30') + str_array[0].to_f * (60 * 60 * 24)
    /(\d+)-(\d+)-(\d+)/ =~ date_time.strftime("%Y-%m-%d")
    year = $1.to_i
    month = $2.to_i
    day = $3.to_i
    str_array.delete_at(0)
    ### 年代
    ages = str_array[0][/(.*?)代/,1] if     str_array[0].include?("代")
    ages = str_array[0]              unless str_array[0].include?("代")
    str_array.delete_at(0)
    ### 性別
#    sex = str_array[0][/(.*?)性/,1]  if str_array[0] =~ /(.*?)性/
    sex = str_array[0]
    str_array.delete_at(0)
    ### 居住地
    location = ""
    location = str_array[0]          if str_array[0] =~ /市|町/
    str_array.delete_at(0)
    ### 職業
    job = str_array[0]
    job = ""           if job.nil?
    str_array.delete_at(0)
    ### 状態
    condition = str_array[0]
    condition = ""           if condition.nil?
    str_array.delete_at(0)
    ###
    hash = Hash.new
    ###
    hash["number"] = person_num
    hash["ages"] = ages
    hash["sex"] = sex
    hash["location"] = location
    hash["date"] = "#{year}/#{month}/#{day}"
    hash["job"] = job
    hash["condition"] = condition
    ###
    covid_hash[person_num] = hash
  end
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
covid_hash["url"] = url
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
