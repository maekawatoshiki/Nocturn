BrowserWindow  = require('browser-window')
JsonLoader     = require('./json-loader')
NodeTwitterApi = require('node-twitter-api')

authWindow = null

module.exports =
class Authentication
  constructor: (callback) ->
    credentials = JsonLoader.read('credentials.json')
    nodeTwitterApi = new NodeTwitterApi({
      callback: 'http://example.com',
      consumerKey: credentials['consumerKey'],
      consumerSecret: credentials['consumerSecret'],
    })

    klass = @
    nodeTwitterApi.getRequestToken((error, requestToken, requestTokenSecret) =>
      url = nodeTwitterApi.getAuthUrl(requestToken)
      authWindow = new BrowserWindow({ width: 800, height: 600 })
      authWindow.webContents.on('will-navigate', (event, url) =>
        event.preventDefault()
        if (matched = url.match(/\?oauth_token=([^&]*)&oauth_verifier=([^&]*)/))
          nodeTwitterApi.getAccessToken(requestToken, requestTokenSecret, matched[2], (error, accessToken, accessTokenSecret) =>
            if error
              authWindow.close()
              new Authentication(callback)
            else
              authWindow.close()
              authWindow = null
              callback({ accessToken: accessToken, accessTokenSecret: accessTokenSecret })
          )
        else
          authWindow.close()
          new Authentication(callback)
      )
      authWindow.on('closed', ->
        # noop
      )
      authWindow.loadUrl(url)
    )
