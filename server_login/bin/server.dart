import 'dart:convert';
import 'dart:io';
import 'dart:core';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

Future<void> main() async {
  // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
  // https://cloud.google.com/run/docs/reference/container-contract#port
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  final cascade = Cascade()
      // First, serve files from the 'public' directory
      .add(_staticHandler)
      // If a corresponding file is not found, send requests to a `Router`
      .add(_router);

  // See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
  final server = await shelf_io.serve(
    // See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
    logRequests()
        // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
        .addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  print('Serving at http://${server.address.host}:${server.port}');

  // Used for tracking uptime of the demo server.
  _watch.start();
}

// Serve files from the file system.
final _staticHandler =
    shelf_static.createStaticHandler('public', defaultDocument: 'index.html');

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..get('/login/<data>', _loginHandler);

String _jsonEncode(Object? data) =>
    const JsonEncoder.withIndent(' ').convert(data);

const _jsonHeaders = {
  'content-type': 'application/json',
};

Response _loginHandler(Request request, String data) {
  RegExp name = new RegExp(r"(0|86|17951)?(13[0-9]|15[0-35-9]|17[0678]|18[0-9]|14[57])[0-9]{8}");
  final userNameStream = name.allMatches(data);
  final userName = userNameStream.group(0);
  final accessCode = data;
  return Response.ok(
    _jsonEncode({'用户名': userName, '密码': accessCode}),
    headers: {
      ..._jsonHeaders,
      'Cache-Control': 'public, max-age=604800, immutable',
    },
  );
}

final _watch = Stopwatch();