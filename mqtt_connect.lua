----------------------------------------------
--
--  Script @ wl-lankin
--
--  Script to send the messured values from a
--  NodeMCU with DHT22 on it to mqtt.
--
----------------------------------------------

local SSID = "wl-lankin-openhab"
local SSID_PASSWORD = "goin!0001g"
local SIGNAL_MODE = wifi.PHYMODE_N

local MTIMER = tmr.create()

MQTT_CLIENT_ID = "NAME" --< TODO change hostname
MQTT_CLIENT_USER = "openhab"
MQTT_CLIENT_PASSWORD = "openhab"
MQTT_CLIENT_KEEPALIVE_TIME = 120

MQTT_BROKER = "192.168.2.92"
MQTT_BROKER_PORT = 1883
MQTT_TOPIC_IN = "/NAME-temp/in" --< TODO set topicname
MQTT_TOPIC_OUT = "/NAME-temp/out" --< TODO set topicname
MQTT_BROKER_SECURE = 0

DHT_PIN = 4

m = nil
temperature = "0"
humidity = "0"

function wait_for_wifi_conn(callback)
  MTIMER:register(1000, 1, function (t)
    if wifi.sta.getip ( ) == nil then
      print ("Waiting for Wifi connection")
    else
      MTIMER:stop()
      print("\n====================================")
      print ("ESP8266 mode is: " .. wifi.getmode ( ))
      print ("The module MAC address is: " .. wifi.ap.getmac ( ))
      print ("Config done, IP is " .. wifi.sta.getip ( ))
      print("====================================")
      callback()
    end
  end)
  MTIMER:start()
end

function mqtt_handler()
  m = mqtt.Client(MQTT_CLIENT_ID, MQTT_CLIENT_KEEPALIVE_TIME, MQTT_CLIENT_USER, MQTT_CLIENT_PASSWORD)
  -- on publish message receive event
  m:on("message", function(client, topic, data)
    print("Received:" .. topic .. ":" )
    if data ~= nil then
      if data == "req" then
        sendValue()
      end
    end
  end)
  m:on("offline", function(m)
    print ("\n\nDisconnected from broker")
    print("Heap: ", node.heap())
  end)
  m:connect(MQTT_BROKER, MQTT_BROKER_PORT, MQTT_BROKER_SECURE, function(client)
    print("connected")
    client:subscribe(MQTT_TOPIC_IN, 0, function(client) print("subscribe success") end)
  end,
  function(client, reason)
    print("failed reason: " .. reason)
  end)
    -- send all 30 sec
  MTIMER:register(30 * 1000, tmr.ALARM_AUTO, function (t)
    sendValue()
  end)
  MTIMER:start()
end

function readDHTValues()
  status, temp, humi, temp_dec, humi_dec = dht.read(DHT_PIN)
  if status == dht.OK then
    temperature = temp
    humidity = humi
  end
end

function sendValue()
  readDHTValues()
  -- publish to broker on topic
  m:publish(MQTT_TOPIC_OUT, temperature, 0, 0, function(client) print("sent value="..temperature) end)
end

-- configure the ESP as a station (client)
wifi.setmode(wifi.STATION)
wifi.setphymode(SIGNAL_MODE)
wifi.sta.config {ssid = SSID, pwd = SSID_PASSWORD}
wifi.sta.autoconnect(1)

-- hang out until we get a wifi connection before mqtt is sending.
wait_for_wifi_conn( mqtt_handler )
