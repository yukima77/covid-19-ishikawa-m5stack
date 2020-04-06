#

### 
require 'date'
require 'json'
require 'octokit'
require_relative 'WebDriver.rb'

##### 変数定義
### URL
URL = "https://www.pref.ishikawa.lg.jp/kansen/coronakennai.html"
REPO="yukima77/covid-19-ishikawa-m5stack"
PREF="Ishikawa"
token=ENV["TOKEN"]
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
  [/ | /, ""],
  [/\( |（ /, "("],
  [/）/, ")"],
  [/（/, "("]
]

###
driver = WebDriver.new("./env-ishikawa.json")
client = Octokit::Client.new access_token: token

###
#GET /repos/:owner/:repo/contents/:path
#s = client.get("/covid-19-ishikawa-m5stack/:yukima77/:repo/contents/:/data/ )
#s = client.get("https://github.com/yukima77/covid-19-ishikawa-m5stack/blob/data/data/covid-19-ishikawa.json")
#s = client.get("https://github.com/yukima77/covid-19-ishikawa-m5stack", branch:"data")

#s = client.contents(REPO, :path => 'data/covid-19-ishikawa.json' )
#s = client.get('/repos/yukima77/covid-19-ishikawa-m5stack.git/contents/data/covid-19-ishikawa.json', branch:"master")
#s = client.get('/repos/yukima77/covid-19-ishikawa-m5stack.git/contents/README.md', branch:"master")

###
status = driver.get(URL)
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
        ###
        covid_hash["#{person_num}"] = hash
      end
      person_num = str[/^(.*?)感染者(\d+)/,2] if item.name == "h3"
    end
    if item.name == "p" then
      ages       = str[/^\((.*?)\)年代(\d+)代/,2] unless str[/^\((.*?)\)年代(\d+)代/].nil?
      sex        = str[/^\((.*?)\)性別(.*?)性/,2]     unless str[/^\((.*?)\)性別(.*?)性/].nil?
      job        = str[/^\(\d\)職業(.*?)/,2]            unless str[/^\(\d\)職業(.*?)/].nil?
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
###
covid_hash["#{person_num}"] = hash
###
covid_hash["last_access"] = Time.now
covid_hash["pref"] = PREF
### JSON出力 (不要だが出力しておく)
File.open("../data/covid-19-ishikawa.json", "w") {|f| 
  f.puts(covid_hash.to_json)
}
###
result = client.contents(REPO, path: "data/covid-19-ishikawa.json", query: {ref: "data"})
result = client.update_contents(REPO, "data/covid-19-ishikawa.json", "Updating content", result[:sha], covid_hash.to_json, :branch => "data", :file => "data/covid-19-ishikawa.json")
