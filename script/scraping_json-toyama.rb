#

### 
require 'date'
require 'json'
require 'octokit'
require_relative 'WebDriver.rb'

##### 変数定義
### 固定値
token = ENV["TOKEN"]
REPO = "yukima77/covid-19-ishikawa-m5stack"
BRANCH = "data"
FORMAT_VERSION="1.0.2"
### URL & pref
URL = "http://www.pref.toyama.jp/cms_sec/1205/kj00021798.html"
REFERER = "http://www.pref.toyama.jp/cms_sec/1205/index.html"
PREF = "Toyama"
JSON_FILE = "data/covid-19-toyama.json"
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
  [/ | |　|\t/, ""],
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
html = driver.page_source
doc = Nokogiri::HTML(html)
### 
nodes = doc.xpath("//*[@id='page_list']")

###
nodes.each {|node|
  node.xpath(".//tr").each {|item|
    str = "#{item.text}"
    grep_array.each {|g_array|
      str.gsub!(g_array[0],g_array[1])
    }
    ### 行頭の改行コードを削除
    str = str.gsub!(/^\n/,"")
    str_array = str.split("\n")
    ###
    if str.include?("令和") or str.include?("月") or str.include?("〃") then
      person_num = str_array[0]
      str_array.delete_at(0)
      ###
      if str.include?("令和") then
        /令和(\d+)年(\d+)月(\d+)日/ =~ str_array[0]
        year = 2018 + $1.to_i
        month = $2.to_i
        day = $3.to_i
      elsif str.include?("月") then
        /(\d+)月(\d+)日/ =~ str_array[0]
        month = $1.to_i
        day = $2.to_i
      end
      str_array.delete_at(0)
      ### 年代
      ages = str_array[0]
      str_array.delete_at(0)
      ### 性別
      sex = str_array[0]
      str_array.delete_at(0)
      ### 居住地
      location = str_array[0]
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
      covid_hash[person_num.to_i] = hash
    end
  }
}
### Hash作成
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
covid_hash[person_num.to_i] = hash
### ソート
covid_hash = Hash[*covid_hash.sort.reverse]
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
result = client.contents(REPO, path: JSON_FILE, query: {ref: BRANCH})
result = client.update_contents(REPO, JSON_FILE, "Updating content at #{last_access}", result[:sha], covid_hash.to_json, :branch => BRANCH, :file => JSON_FILE)
