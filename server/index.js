const express = require("express");
const bodyParser = require("body-parser");
const fs = require("fs");
const readLastLines = require("read-last-lines");
var admin = require("firebase-admin");
var serviceAccount = require("/home/hades/server_test/privatekey_tinyos.json"); // Or your config object as above.
const file = "output.txt";
const cors = require("cors");
const app = express();

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount), 
  databaseURL: "https://tiny-os-eaa13.firebaseio.com/",
});

var db = admin.database();
var ref = db.ref("/");

app.use(cors());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

fs.watchFile(file, (curr, prev) => {
  readLastLines.read(file, 1).then((lines) => {
    if (lines.length > 40) {
      let temperatureHex = lines[30] + lines[31] + lines[33] + lines[34];
      let humidityHex = lines[36] + lines[37] + lines[39] + lines[40];
      let visibleLight = lines[42] + lines[43] + lines[45] + lines[46];
      let infraredLightHex = lines[48] + lines[49] + lines[51] + lines[52];
      let T = parseInt(temperatureHex, 16);
      let H = parseInt(humidityHex, 16);
      let L = parseInt(visibleLight, 16);
      let temperature = parseFloat(-39.6 + 0.01 * T).toFixed(2);
      let humidityL =
        -2.0468 + 0.0367 * H - 1.5955 * Math.pow(10, -6) * Math.pow(H, 2);
      let humidityT = parseFloat(
        (temperature - 25) * (0.01 + 0.00008 * H) + humidityL
      ).toFixed(2);
      let light = parseFloat(
        0.625 * Math.pow(10, 6) * ((L / 4096) * 1.5) * Math.pow(10, -5) * 1000
      ).toFixed(2);
      ref.update({
        humidity: humidityT,
        light: light,
        temp: temperature,
      });
      console.log("updated");
      
    }
  });
});
