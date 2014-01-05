## Mail.ru REST API client for node

This npm module allows you to simplify making API requests into mail.ru REST API.
## Example usage

```coffeescript
mailru = require('mailru-api')

# Basic configuration params
requestOptions =
  applicationSecretKey: 'secretKey'
  applicationId: 'appId'

mailru.setOptions(requestOptions)
# You can specify accessToken in requestOptions or separately
# For example: if you have many users and you whant to iterate through them
mailru.setAccessToken('accessToken')

# All data passed in Object
mailru.get { method: 'users.getInfo' }, (err, data) ->
  # Some actions with data

# You can also specify types of requests
mailru.post, mailru.get
```

Refresh user token method
```coffeescript
ok.refresh '{refresh_token}', (err, data) ->
  data.access_token # new token
```

Enjoy!


TODO
----
* What do you need? Let me know or fork.