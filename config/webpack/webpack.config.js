const path = require('path')
const webpack = require('webpack')

const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production'

module.exports = {
  mode,
  optimization: {
    moduleIds: 'hashed'
  },
  entry: {
    application: './app/javascript/application.js'
  },
  output: {
    filename: '[name].js',
    sourceMapFilename: '[name].js.map',
    path: path.resolve(__dirname, '..', '..', 'app/assets/builds')
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    })
  ],
  module: {
    rules: [
      {
        test: /\.(js|jsx|ts|tsx|)$/,
        exclude: /node_modules/,
        use: ['babel-loader']
      }
    ]
  }
}
