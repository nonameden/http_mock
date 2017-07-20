# http_mock
[![Pub](https://img.shields.io/pub/v/http_mockr.svg)](https://pub.dartlang.org/packages/http_mockr)
[![build status](https://travis-ci.org/thosakwe/http_mockr.svg)](https://travis-ci.org/thosakwe/http_mockr)

A package:http client that can mock server responses.

# Usage
Instead of sending requests over a network, the `MockClient` class is also
a server in itself. It uses the cross-platform `angel_route` library to provide
you with a routing solution that supports path parameters and middleware out-of-the-box.

All your handlers just need to accept a `MockHttpContext`. If they return `true`, then
other handlers will be allowed to run (effectively accomplishing a middleware concept).
Otherwise, the return value will be processed.

You can return:
* a `Response` or `StreamedResponse`
* `null` or nothing - do not write anything else to the server
* Anything else - will be serialized via `JSON.encode`

```dart
var client = new http.MockClient();

client.router
  ..get('/hello/:name', (http.MockHttpContext ctx) {
    // Return a plain response
    return new http.Response('Hello, ${ctx.request.params["name"]}!', 200);
  })
  ..all('*', (http.MockHttpContext ctx) {
    return new http.Response('404 Not Found', 404);
  });

// And then, in a test...
var response = await client.get('/hello/world');
expect(response.body, 'Hello, world!');

```