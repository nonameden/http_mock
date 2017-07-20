import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_mock/http_mock.dart' as http;
import 'package:test/test.dart';

main() {
  http.MockClient client;

  setUp(() {
    client = new http.MockClient();

    client.router
      ..get('/hello', (http.MockHttpContext ctx) {
        // Return a plain response
        return new http.Response('Hello, world!', 200);
      })
      ..post('/json', (http.MockHttpContext ctx) async {
        var json = await ctx.request.body
            .transform(UTF8.decoder)
            .join()
            .then(JSON.decode);
        ctx.response
          ..headers['content-type'] = 'application/json'
          ..write(JSON.encode(json))
          ..close();
      })
      ..get('/accept', (http.MockHttpContext ctx) {
        ctx.response.write(ctx.request.accepts('text/html') ? 'yes' : 'no');
      })
      ..all('*', (http.MockHttpContext ctx) {
        return new http.Response('404 Not Found', 404);
      });
  });

  test('return http.Response', () async {
    var response = await client.get('/hello');
    print('Response: ${response.body}');
    expect(response.body, 'Hello, world!');
    expect(response.statusCode, 200);
  });

  test('post a body', () async {
    var data = {'foo': 'bar'};
    var response = await client.post('/json',
        body: JSON.encode(data), headers: {'content-type': 'application/json'});
    print('Response: ${response.body}');
    expect(JSON.decode(response.body), data);
    expect(response.headers['content-type'], 'application/json');
  });

  test('accepts', () async {
    var response = await client.get('/accept');
    expect(response.body, 'no');
    response =
        await client.get('/accept', headers: {'accept': 'application/json'});
    expect(response.body, 'no');
    response = await client.get('/accept', headers: {'accept': '*/*'});
    expect(response.body, 'yes');
    response = await client.get('/accept', headers: {'accept': 'text/html'});
    expect(response.body, 'yes');
    response = await client
        .get('/accept', headers: {'accept': 'text/html,application/json'});
    expect(response.body, 'yes');
  });

  test('fallback to 404', () async {
    var response = await client.get('/wtf');
    print('Response: ${response.body}');
    expect(response.body, '404 Not Found');
    expect(response.statusCode, 404);
  });
}
