
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

mixin HttpClient {

  Map<String, String> get defaultHeaders =>
      {
        "Content-Type" : "application/json",
        "Accept": "application/json"
      };

  Map<String, String> defaultHeadersWith(Map map) => {...defaultHeaders, ...map};

  Future<RetryClient> getRetryClient() async {
    final client = RetryClient(http.Client(),
        when: (response) => ![200,500,400,404,405].contains(response.statusCode));
    return client;
  }

  Future<http.Response> httpGet(Uri url, {Map<String, String>? headers }) async {
    final client = await getRetryClient();
    try {
      return await client.get(url, headers: headers ?? defaultHeaders);
    } finally {
      client.close();
    }
  }

  Future<http.Response> httpPost(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final client = await getRetryClient();
    try {
      return await client.post(url, body: body, headers: headers ?? defaultHeaders, encoding: encoding);
    } finally {
      client.close();
    }
  }

  Future<http.Response> httpPut(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final client = await  getRetryClient();
    try {
      return await  client.put(url, body: body, headers: headers ?? defaultHeaders, encoding: encoding);
    } finally {
      client.close();
    }
  }

  Future<http.Response> httpDelete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final client = await  getRetryClient();
    try {
      return await  client.delete(url, body: body, headers: headers ?? defaultHeaders, encoding: encoding);
    } finally {
      client.close();
    }
  }

  T decode<T>(http.Response resp) =>
      json.decode(utf8.decode(resp.bodyBytes));


}