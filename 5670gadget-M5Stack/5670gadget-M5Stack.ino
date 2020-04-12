#include <M5Stack.h>
#include <WiFi.h>
#include <HTTPClient.h>
#define JST     3600* 9

// ★★★★★設定項目★★★★★★★★★★
const char* ssid     = "xxxxxxxx";       // 自宅のWiFi設定
const char* password = "xxxxxxxx";

//String displayName = "5670 Gadget  TOYAMA";
//String url = "https://raw.githubusercontent.com/yukima77/covid-19-ishikawa-m5stack/data/data/covid-19-toyama.json";
String displayName = "5670 Gadget  ISHIKAWA";
String url = "https://raw.githubusercontent.com/yukima77/covid-19-ishikawa-m5stack/data/data/covid-19-ishikawa.json";
//String displayName = "5670 Gadget  FUKUI";
//String url = "https://raw.githubusercontent.com/yukima77/covid-19-ishikawa-m5stack/data/data/covid-19-fukui.json";
// ★★★★★★★★★★★★★★★★★★★

int preSum = -1;

void setup() {
  M5.begin();
  M5.Lcd.setBrightness(192);

  // シリアル設定
  Serial.begin(115200);
  Serial.println("");

  //
  M5.Lcd.setCursor(0, 5);
  M5.Lcd.setTextSize(2);
  M5.Lcd.println("WIFI CONNECTING...");

  // WiFi接続
  wifiConnect();
  delay(1000);

  // NTP同期
  configTime( JST, 0, "ntp.nict.jp", "ntp.jst.mfeed.ad.jp");

}

void loop() {

  time_t t;
  struct tm *tm;
  static const char *wd[7] = {"Sun", "Mon", "Tue", "Wed", "Thr", "Fri", "Sat"};

  t = time(NULL);
  tm = localtime(&t);

  Serial.printf(" %04d/%02d/%02d(%s) %02d:%02d:%02d\n",
                tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
                wd[tm->tm_wday],
                tm->tm_hour, tm->tm_min, tm->tm_sec);

  // STAモードで接続出来ていない場合
  if (WiFi.status() != WL_CONNECTED) {
    M5.Lcd.clear(BLACK);
    M5.Lcd.setCursor(0, 0);
    M5.Lcd.setTextSize(2);
    M5.Lcd.println("NOT CONNECTED WIFI.");
    M5.Lcd.println("RETRYING NOW...");
    wifiConnect();
  }

  // WiFiに接続されている場合
  if (WiFi.status() == WL_CONNECTED) {
    int sum = getCovidData();
    // 正しくデータが取得できたかどうか
    if (sum >= 0) {
      // 感染者数に変化があったかどうか
      if (sum != preSum) {
        M5.Lcd.clear(BLACK);
        M5.Lcd.setCursor(0, 5);
        M5.Lcd.setTextSize(2);
        M5.Lcd.println(displayName);
        M5.Lcd.setCursor(120, 100);
        M5.Lcd.setTextSize(7);
        M5.Lcd.println(String(sum));
      }

      // アップデート時刻の表示
      String updateTime = String(tm->tm_mon + 1) + "/" + String(tm->tm_mday) + " "
                          + String(tm->tm_hour) + ":" + String(tm->tm_min);
      M5.Lcd.setCursor(20, 215);
      M5.Lcd.setTextSize(2);
      M5.Lcd.println("Updated: " + updateTime);

      // 値を保持
      preSum = sum;

    } else {
      // error
    }
  } else {
  }

  // 時間待ち
  delay(30000);
  M5.update();
}

void wifiConnect() {
  Serial.print("Connecting to " + String(ssid));

  //WiFi接続開始
  WiFi.begin(ssid, password);

  //接続を試みる(30秒)
  for (int i = 0; i < 60; i++) {
    if (WiFi.status() == WL_CONNECTED) {
      //接続に成功。IPアドレスを表示
      Serial.println();
      Serial.print("Connected! IP address: ");
      Serial.println(WiFi.localIP());
      break;
    } else {
      Serial.print(".");
      delay(500);
    }
  }

  // WiFiに接続出来ていない場合
  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("");
    Serial.println("Failed, Wifi connecting error");
  }

}

// コロナ情報のアップデート
int getCovidData(void) {

  int res;
  HTTPClient https;

  //String url = "https://www.pref.ishikawa.lg.jp/kansen/coronakennai.html";
  Serial.print("connect url :");
  Serial.println(url);

  Serial.print("[HTTPS] begin...\n");
  if (https.begin(url)) {  // HTTPS

    Serial.print("[HTTPS] GET...\n");
    // start connection and send HTTP header
    int httpCode = https.GET();

    // httpCode will be negative on error
    if (httpCode > 0) {
      // HTTP header has been send and Server response header has been handled
      Serial.printf("[HTTPS] GET... code: %d\n", httpCode);
      //Serial.println(https.getSize());

      // file found at server
      String payload;
      if (httpCode == HTTP_CODE_OK || httpCode == HTTP_CODE_MOVED_PERMANENTLY) {
        payload = https.getString();
        Serial.println("HTTP_CODE_OK");
        Serial.println(payload);
      }

      int num_start = payload.indexOf("\"");
      int num_end = payload.indexOf("\":");
      //Serial.println(num_start);
      //Serial.println(num_end);

      String garbageDays = {"\0"};
      garbageDays = payload.substring(num_start + 1, num_end);
      res = garbageDays.toInt();
      Serial.println(res);

    } else {
      Serial.printf("[HTTPS] GET... failed, error: %s\n", https.errorToString(httpCode).c_str());
      res = -1;
    }
    https.end();
  } else {
    Serial.printf("[HTTPS] Unable to connect\n");
    res = -1;
  }

  return res;

}
