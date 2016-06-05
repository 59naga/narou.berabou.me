import koutoSwiss from 'kouto-swiss';

export default {
  entry: './src',
  module: {
    loaders: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: 'babel',
      },
      {
        test: /\.styl$/,
        loader: 'style!css?sourceMap!stylus',
      },
      {
        test: /\.(otf|eot|woff|woff2|ttf|svg|png|jpg)$/,
        loader: 'url?name=[name]-[hash].[ext]',
      },
    ],
  },
  devServer: {
    noInfo: true,
    quiet: true,
  },
  stylus: {
    use: [koutoSwiss()],
  },

  devtool: '#source-map',
};
