#

### 
require 'date'
require 'json'
require 'octokit'
require_relative 'WebDriver.rb'

##### 変数定義
### URL & pref
URL = "http://www.pref.toyama.jp/cms_sec/1205/kj00021798.html"
PREF = "Toyama"
###
num = 1
person_num = 0
ages = ""
sex = ""
location = ""
job = ""
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
driver = WebDriver.new("./env-toyama.json")
###
status = driver.get(URL)
html = driver.page_source
doc = Nokogiri::HTML(html)
### 
nodes = doc.xpath("//*[@id='main']")

###
nodes.each {|node|
  node.xpath(".//h4|p").each {|item|
    str = "#{item.text}"
    grep_array.each {|g_array|
      str.gsub!(g_array[0],g_array[1])
    }
    ### 確定日取得
    if item.name == "h4" then
      /令和(\d+)年(\d+)月(\d+)日/ =~ str
      year = 2018 + $1.to_i
      month = $2.to_i
      day = $3.to_i
    end
    ### 事例数取得
    if item.name == "p" then
      item.children.each {|element|
        str = element.text
        grep_array.each {|g_array|
          str.gsub!(g_array[0],g_array[1])
        }
        unless str[/^◎(\d+)例目/].nil?
          # データ確定
          unless person_num == 0 then
            hash = Hash.new
            ###
            hash["number"] = person_num
            hash["ages"] = ages
            hash["sex"] = sex
            hash["location"] = location
            hash["date"] = "#{year}/#{month}/#{day}"
            ###
            covid_hash["#{person_num}"] = hash
          end
          person_num = str[/^◎(\d+)例目/,1]            unless str[/^◎(\d+)例目/].nil?
        end
        ages       = str[/^\((.*?)\)年代(\d+)歳代/,2] unless str[/^\((.*?)\)年代(\d+)歳代/].nil?
        sex        = str[/^\((.*?)\)性別(.*?)性/,2]   unless str[/^\((.*?)\)性別(.*?)性/].nil?
        job        = ""
        #
        /(^\((.*?)\)(居住地)(.*?))/ =~ str
        s = $1
        location   = str.gsub(s,'')          unless s.nil?
      }
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
###
covid_hash["#{person_num}"] = hash
###
covid_hash["last_access"] = Time.now
covid_hash["pref"] = PREF
### JSON出力
p covid_hash.to_json
