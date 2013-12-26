request = require('request')
md5     = require('blueimp-md5').md5
qs      = require('querystring')
_       = require('underscore')

# Default options
requestOptions =
  applicationSecretKey: null
  applicationId: null
  sessionKey: null
  refreshToken: null
  # Default base urls where request's go
  restBase: 'http://www.appsmail.ru/platform/api'
  refreshBase: 'https://appsmail.ru/oauth/token'

# It's like that and that's the way it is
class MailruApi

  # We can construct requests on-fly
  # By doing this:
  #
  #   mailru = require('./mailru_api')
  #   mailru.setOptions(requestOptions)
  #   mailru.setsessionKey(requestOptions)
  #
  # And using verbs: (POST, GET)
  #   ok.(get|post) { method: 'users.getInfo' }, (err, data) ->
  #     console.log response
  #
  #  ❨╯°□°❩╯︵┻━┻
  constructor: (method, postData, callback) ->
    validateOptions()
    makeRequest(method, postData, callback)

  # private methods goes below ^_^

  makeRequest = (method, postData, callback) ->
    requestedData =
      app_id: requestOptions['applicationId']
      session_key: requestOptions['sessionKey']
      sig: makeSignature(postData)

    _.extend(requestedData, postData)

    switch method.toUpperCase()
      when 'POST'
        request.post {
          uri: requestOptions['restBase']
          json: true
          headers: 'content-type': 'application/x-www-form-urlencoded'
          body: qs.stringify(requestedData)
        }, (error, response, body) ->
          _responseHandler(error, response, body, callback)
      when 'GET'
        getUrl = "#{requestOptions['restBase']}?" + parametrize(requestedData, '&')
        request.get { uri: getUrl, json: true }, (error, response, body) ->
          _responseHandler(error, response, body, callback)
      else
        throw 'HTTP verb not supported'

  # Just apply that rules from http://api.mail.ru/docs/guides/restapi/
  makeSignature = (postData) ->
    # Additional params that included into signature
    postData['app_id']      = requestOptions['applicationId']
    postData['session_key'] = requestOptions['sessionKey']
    postData['secure']      = 1 # Server-server connection

    sortedParams = parametrize(postData)
    secret       = requestOptions['applicationSecretKey']

    md5 sortedParams + secret

  # Method that helps made string of parameters for objects
  parametrize = (obj, join = false) ->
    arrayOfArrays = _.pairs(obj).sort()

    symbol = if join then '&' else ''

    sortedParams = ''
    _.each arrayOfArrays, (value) ->
      sortedParams += "#{_.first(value)}=#{_.last(value)}" + symbol

    return sortedParams

  validateOptions = ->
    unless requestOptions['applicationId']? || requestOptions['applicationSecretKey']?
      throw 'Please setup requestOptions with valid params. @see https://github.com/astronz/mailru-api-node'
    unless requestOptions['sessionKey']?
      throw 'sessionKey does not initialized. @see https://github.com/astronz/mailru-api-node'

# Exports api as class
exports.api = MailruApi

_responseHandler = (error, response, body, callback) ->
  if error? # HTTP error
    callback(error, body, response)
  else
    error = body.error if body.hasOwnProperty('error') # API error
    callback(error, body, response)

#
# Refresh user token to new one
#
exports.refresh = (refreshToken, callback) ->
  requestOptions['refreshToken'] = refreshToken

  refresh_params =
    refresh_token: requestOptions['refreshToken']
    grant_type: 'refresh_token',
    client_id: requestOptions['applicationId'],
    client_secret: requestOptions['applicationSecretKey']

  request.post {
    uri: requestOptions['refreshBase']
    json: true
    headers: 'content-type': 'application/x-www-form-urlencoded'
    body: qs.stringify(refresh_params)
  }, (error, response, body) ->
    _responseHandler(error, response, body, callback)

#
# Prepares POST request for API
#
exports.post = (params, callback) ->
  new MailruApi 'POST', params, callback

#
# Prepares POST request for API
#
exports.get = (params, callback) ->
  new MailruApi 'GET', params, callback

# Set needed sessionKey
exports.setSessionKey = (token) ->
  _.extend(requestOptions, {sessionKey: token})

# Gets accesToken
exports.getSessionKey = ->
  requestOptions['sessionKey']

# Setup global requestOptions
exports.setOptions = (options) ->
  if typeof options == 'object'
    _.extend(requestOptions, options)

# Gets options
exports.getOptions = ->
  requestOptions
