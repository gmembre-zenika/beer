"use strict";
const five = require("johnny-five");
const board = new five.Board();


board.on("ready", function() {
    const flow = new five.Pin(2);
    var pulses = 0;
    var lastflowpinstate = 0;

    setInterval(function() {
        flow.read((error, value) => {
            if (value == lastflowpinstate) {
                return;
            }
            if (value == 1) {
                pulses++;
            }
            lastflowpinstate = value;
        });
    }.bind(this), 1);

    this.loop(1000, () => {
        // if a plastic sensor use the following calculation
        // Sensor Frequency (Hz) = 7.5 * Q (Liters/min)
        // Liters = Q * time elapsed (seconds) / 60 (seconds/minute)
        // Liters = (Frequency (Pulses/second) / 7.5) * time elapsed (seconds) / 60
        // Liters = Pulses / (7.5 * 60)
        var liters = pulses;
        liters /= 7.5;
        liters /= 60;
        console.log(`Liters : ${liters}`); 
    });
});
