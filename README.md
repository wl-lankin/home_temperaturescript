# Temperature script

### Script @ wl-lankin

Script to send the messured values from a
NodeMCU with DHT22 on it to mqtt.

##### OpenHAB2

###### temperature.items
```
Number Temperature "Temperatur [%.1f°C]" <temperature> { mqtt="<[broker:/temp/out:state:REGEX((.*?))]"}
```

###### main.sitemap:
```
Text item=Temperature
```
