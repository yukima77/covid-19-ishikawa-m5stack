#include <M5Stack.h>
#include <WiFi.h>
#include <HTTPClient.h>
#define JST     3600* 9

// ★★★★★設定項目★★★★★★★★★★
const char* ssid     = "xxxxxxxx";       // 自宅のWiFi設定
const char* password = "xxxxxxxx";
// ★★★★★★★★★★★★★★★★★★★

void setup() {
  M5.begin();
  M5.Lcd.setBrightness(192);

  // シリアル設定
  Serial.begin(115200);
  Serial.println("");

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
    int num = getCovidData();
    if (num > 0) {
      M5.Lcd.clear(BLACK);
      M5.Lcd.setCursor(0, 0);
      M5.Lcd.setTextSize(3);
      M5.Lcd.println("COVID-19 ISHIKAWA");
      M5.Lcd.setCursor(120, 100);
      M5.Lcd.setTextSize(7);
      M5.Lcd.println(String(num));
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

  String url = "https://www.pref.ishikawa.lg.jp/kansen/coronakennai.html";
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
        //Serial.println(payload);
      }

      int num = payload.indexOf("感染者");
      //Serial.println(num);

      String garbageDays = {"\0"};
      garbageDays = payload.substring(num + 9, num + 11);
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
