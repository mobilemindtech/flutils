
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import 'http_client.dart';

extension HttpClientIO on HttpClient {
  IO<http.Response> httpPostIO(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return IO.attempt(() =>
        httpPost(url, headers: headers, body: body, encoding: encoding));
  }

  IO<http.Response> httpGetIO(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return IO.attempt(() =>
        httpGet(url, headers: headers));
  }

  IO<T> decodeIO<T>(http.Response response) {
    return IO.attempt(() => json.decode(response.body));
  }

  IO<T> Function(http.Response) decodeNestedIO<T>(String key) {
    return (response) => IO.attempt(() => json.decode(response.body)[key]);
  }
}