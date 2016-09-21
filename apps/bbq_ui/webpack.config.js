var ExtractTextPlugin = require("extract-text-webpack-plugin");
var CopyWebpackPlugin = require('copy-webpack-plugin');
var extractCSSPlugin = new ExtractTextPlugin("css/[name].css");
var copyStaticAssets = new CopyWebpackPlugin([{from: "./web/static/assets"}]);

module.exports = {
    entry: {
        app: [
            "./web/static/js/app.js",
            "./web/static/css/app.css",
            "./web/static/elm/Dashboard.elm"
        ]
    },
    output: {
        path: "./priv/static",
        filename: "js/[name].js"
    },
    module: {
        loaders: [
            {
                test: /\.js$/,
                include: __dirname,
                exclude: /(node_modules)/,
                loader: 'babel',
                query: {
                    presets: ['es2015']
                }
            },
            {
                test: /\.css$/,
                exclude: /(node_modules)/,
                loader: extractCSSPlugin.extract('css')
            },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: 'elm-webpack?cwd=./web/static/elm/'
            }
        ]
    },
    plugins: [
        extractCSSPlugin,
        copyStaticAssets
    ]
};