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
URL = "https://www.pref.fukui.lg.jp/doc/kenkou/kansensyo-yobousessyu/corona.html"
REFERER = "https://www.pref.fukui.lg.jp/kenko/kenkou/cat0902/index.html"
PREF = "Fukui"
JSON_FILE=  "data/covid-19-fukui.json"
ENV_FILE = "./env-fukui.json"
###
comment = "福井県版JSONファイル"
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
nodes = doc.xpath("//*[@id='content']/div")

###
nodes.each {|node|
  node.xpath(".//tr").each {|item|
    str = "#{item.text}"
    grep_array.each {|g_array|
      str.gsub!(g_array[0],g_array[1])
    }
    ### 行頭の改行コードを削除
    str = str.gsub!(/^\r\n/,"")
    str_array = str.split("\r\n")
    ###
    if str.include?("例目") then
      person_num = str[/^(\d+)例目/,1] if item.text.include?("例目")
      str_array.delete_at(0)
      ###
      if str.include?("令和") then
        /令和(\d+)年(\d+)月(\d+)日/ =~ str_array[0]
        year = 2018 + $1.to_i
        month = $2.to_i
        day = $3.to_i
        ###
        str_array.delete_at(0)
      end
      ### 年代
      if str_array[0] =~ /\d\d/ then
        ages = str_array[0]
        str_array.delete_at(0)
      end
      ### 性別
      if str_array[0] =~ /(.*?)性/ then
        sex        = str_array[0][/(.*?)性/]
        str_array.delete_at(0)
      end
      ### 居住地
      if str_array[0] =~ /市|町/ then
        location = str_array[0]
        str_array.delete_at(0)
      end
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
covid_hash = covid_hash.sort.reverse.to_h
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
