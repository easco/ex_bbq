var Chart = require('chart.js')
var Elm = require('../elm/Dashboard.elm')
var URI = require('uri-js')

import AppModule from './app_module'

function createChart(temperature_samples) {
    temperature_samples = temperature_samples.reverse()

    var labels = temperature_samples.map(sample => { return sample[0] })

    var values = temperature_samples.map(function(x) {
        return x[1]
    })

    var ctx = document.getElementById("myChart");
    window.temperatureChart = new Chart.Line(ctx, {
        data: {
            labels: labels,
            datasets: [
            {
                label: "Cooking Data",
                lineTension: 0.1,
                data: values
            }
            ]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        min: 0,
                        max: 350
                    }
                }]
            }
        }
    });
}

function updateChart(temperature_samples) {
    temperature_samples = temperature_samples.reverse()

    var labels = temperature_samples.map(function(x) {
        return x[0]
    })

    var values = temperature_samples.map(function(x) {
        return x[1]
    })

    window.temperatureChart.data.labels = labels
    window.temperatureChart.data.datasets[0].data = values
    window.temperatureChart.update()
}

function socketURL() {
    var url = URI.serialize(
        {
            scheme : "ws",
            host: window.location.host,
            port: window.location.port,
            path: "/socket/websocket"
        }
    )

    return unescape(url)
}

export default class Cooking extends AppModule {
  moduleWillShow () {
    console.log("Cooking.moduleWillShow")

            // Set up our Elm App
    const elmDiv = document.querySelector("#elm-container");
    const elmApp = Elm.TemperatureTracking.embed(elmDiv,
            {
                socket: socketURL()
            }
        );

    elmApp.ports.callCreateGraph.subscribe(createChart)
    elmApp.ports.callUpdateGraph.subscribe(updateChart)
  }

  moduleWillHide () {
    console.log("Cooking.moduleWillHide")
  }
}