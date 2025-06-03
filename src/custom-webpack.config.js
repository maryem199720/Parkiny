const webpack = require('webpack');

   console.log('Custom Webpack config loaded');

   module.exports = {
     resolve: {
       fallback: {
         async_hooks: false,
         crypto: require.resolve('crypto-browserify'),
         fs: false,
         http: require.resolve('stream-http'),
         net: false,
         path: require.resolve('path-browserify'),
         querystring: require.resolve('querystring-es3'),
         stream: require.resolve('stream-browserify'),
         url: require.resolve('url/'),
         util: require.resolve('util/'),
         zlib: require.resolve('browserify-zlib'),
         process: require.resolve('process/browser'),
         buffer: require.resolve('buffer/')
       }
     },
     plugins: [
       new webpack.ProvidePlugin({
         global: 'globalthis',
         process: 'process/browser',
         Buffer: ['buffer', 'Buffer']
       })
     ]
   };