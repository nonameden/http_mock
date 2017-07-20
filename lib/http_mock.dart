import 'dart:async';
import 'dart:convert';
import 'package:angel_route/angel_route.dart';
import 'package:http/src/base_client.dart';
import 'package:http/src/base_request.dart';
import 'package:http/src/response.dart';
import 'package:http/src/streamed_response.dart';

class MockClient extends BaseClient {
  final Router router = new Router();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    var resolved = router.resolveAll(request.url.path, request.url.path,
        method: request.method);
    var pipeline = new MiddlewarePipeline(resolved);
    var params = resolved.fold<Map>({}, (out, r) => out..addAll(r.allParams));

    var req = new MockHttpContextRequest._(request.method, request.url,
        request.headers, params, request.finalize());
    var res = new MockHttpContextResponse._();
    var ctx = new _MockHttpContextImpl(req, res);

    var result;

    for (var handler in pipeline.handlers) {
      result = await handler(ctx);
      if (result != true) break;
    }

    if (result is StreamedResponse) {
      if (!res._closed) res.close();
      return result;
    } else if (result is Response) {
      if (!res._closed) res.close();
      return new StreamedResponse(
          new Stream<List<int>>.fromIterable([result.bodyBytes]),
          result.statusCode,
          request: request,
          headers: result.headers,
          reasonPhrase: result.reasonPhrase,
          contentLength: result.contentLength,
          persistentConnection: result.persistentConnection,
          isRedirect: result.isRedirect);
    } else {
      // Send a response...
      if (result != null && !res._closed) {
        res
          ..headers['content-type'] = 'application/json'
          ..write(JSON.encode(result));
      }

      if (!res._closed) res.close();
      return new StreamedResponse(res._body.stream, res.statusCode ?? 200,
          headers: res.headers);
    }
  }
}

abstract class MockHttpContext {
  MockHttpContextRequest get request;
  MockHttpContextResponse get response;
}

class _MockHttpContextImpl implements MockHttpContext {
  @override
  final MockHttpContextRequest request;

  @override
  final MockHttpContextResponse response;

  _MockHttpContextImpl(this.request, this.response);
}

class MockHttpContextRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers, params;
  final Stream<List<int>> body;
  final Map<String, dynamic> properties = {};

  MockHttpContextRequest._(
      this.method, this.url, this.headers, this.params, this.body);

  /// Returns `true` if the client accepts the given MIME type as a response.
  bool accepts(String mimeType) {
    return headers['accept'] == '*/*' ||
        headers['accept']
                ?.split(',')
                ?.map((s) => s.trim())
                ?.contains(mimeType) ==
            true;
  }
}

class MockHttpContextResponse
    implements Sink<List<int>>, StreamSink<List<int>>, StringSink {
  final StreamController<List<int>> _body = new StreamController<List<int>>();
  bool _closed = false;
  int statusCode = 200;
  final Map<String, String> headers = {};

  MockHttpContextResponse._();

  @override
  Future addStream(Stream<List> stream) {
    return _body.addStream(stream).then((_) {
      _closed = true;
    });
  }

  @override
  void write(Object obj) {
    _body.add(UTF8.encode(obj.toString()));
  }

  @override
  Future close() {
    _closed = true;
    return _body.close();
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    _body.addError(error, stackTrace);
  }

  @override
  void writeCharCode(int charCode) {
    _body.add([charCode]);
  }

  @override
  Future get done {
    return _body.done;
  }

  @override
  void writeln([Object obj = ""]) {
    if (obj != null) write(obj);
    write('\n');
  }

  @override
  void add(List data) {
    _body.add(data);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    write(objects.join(separator));
  }
}
