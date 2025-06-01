// C:\frontttt\Smart-park\src\costum-webpack.config.js
module.exports = {
  resolve: {
    fallback: {
      async_hooks: false,
      crypto: false,
      fs: false,
      http: false,
      net: false,
      path: false,
      querystring: false,
      stream: false,
      url: false,
      util: false,
      zlib: false,
      process: false
    }
  }
};