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
URL = "https://www.pref.ishikawa.lg.jp/kansen/coronakennai.html"
REFERER = "https://www.pref.ishikawa.lg.jp/kansen/corona.html"
PREF = "Ishikawa"
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
nodes = doc.xpath("//*[@id='tmp_contents']")
###
nodes.each {|node|
  node.xpath(".//h2|h3|p").each {|item|
    str = "#{item.text}"
    grep_array.each {|g_array|
      str.gsub!(g_array[0],g_array[1])
    }
    ### 確定日取得
    if item.name == "h2" then
      /令和(\d+)年(\d+)月(\d+)日/ =~ str
      year = 2018 + $1.to_i
      month = $2.to_i
      day = $3.to_i
    end
    ### 事例数取得
    if item.name == "h3" then
      # データ確定
      unless person_num == 0 then
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
      person_num = str[/^(.*?)感染者(\d+)/,2] if item.name == "h3"
    end
    if item.name == "p" then
      ages       = str[/^\((.*?)\)年代(\d+)代/,2] unless str[/^\((.*?)\)年代(\d+)代/].nil?
      sex        = str[/^\((.*?)\)性別(.*?)性/,2] unless str[/^\((.*?)\)性別(.*?)性/].nil?
      job        = str[/^\(\d\)職業(.*?)/,2]      unless str[/^\(\d\)職業(.*?)/].nil?
      job        = "" if job.nil?
      #
      /(^\((.*?)\)(居住地)(.*?))/ =~ str
      s = $1
      location   = str.gsub(s,'')          unless s.nil?
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
covid_hash[person_num] = hash
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
