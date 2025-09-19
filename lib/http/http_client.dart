
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

typedef Retry = FutureOr<bool> Function(http.BaseResponse);

mixin HttpClient {

  Map<String, String> get defaultHeaders =>
      {
        "Content-Type" : "application/json",
        "Accept": "application/json"
      };

  Map<String, String> defaultHeadersWith(Map map) => {...defaultHeaders, ...map};

  RetryClient get defaultClient  => RetryClient(http.Client());


  Future<http.Response> httpGet(Uri url, {Map<String, String>? headers, RetryClient? retryClient}) async {
    final client = retryClient ?? defaultClient;
    return client.get(url, headers: headers ?? defaultHeaders)
        .whenComplete(() => client.close());
  }

  Future<http.Response> httpPost(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding, RetryClient? retryClient}) async {
    final client = retryClient ?? defaultClient;
      return client.post(url, body: body, headers: headers ?? defaultHeaders, encoding: encoding)
        .whenComplete(() => client.close());
  }

  Future<http.Response> httpPut(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding, RetryClient? retryClient}) async {
    final client = retryClient ?? defaultClient;
    return client.put(url, body: body, headers: headers ?? defaultHeaders, encoding: encoding)
          .whenComplete(() => client.close());
  }

  Future<http.Response> httpDelete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding, RetryClient? retryClient}) async {
    final client = retryClient ?? defaultClient;
    return client.delete(url, body: body, headers: headers ?? defaultHeaders, encoding: encoding)
        .whenComplete(() => client.close());
  }

  T decode<T>(http.Response resp) =>
      json.decode(utf8.decode(resp.bodyBytes));
}