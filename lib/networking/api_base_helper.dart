import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum RequestType { get, post, put, delete }

class ApiBaseHelper {
  static const String ip = "192.168.1.19"; // Change to your local IP
  static const String baseUrlRemote = "https://api.example.com"; // Production
  static const String baseUrlLocalWeb = "http://localhost:3000";
  static const String baseUrlLocalAndroid = "http://$ip:3000";
  static const String baseUrlLocalIos = "http://$ip:3000";

  final String baseUrl = kReleaseMode
      ? baseUrlRemote
      : kIsWeb
          ? baseUrlLocalWeb
          : defaultTargetPlatform == TargetPlatform.android
              ? baseUrlLocalAndroid
              : baseUrlLocalIos;

  final Map<String, String> _defaultHeaders = {
    "Content-Type": "application/json",
  };

  Future<dynamic> request(
    RequestType type,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    http.Response response;

    try {
      switch (type) {
        case RequestType.get:
          response = await http.get(url, headers: headers ?? _defaultHeaders);
          break;
        case RequestType.post:
          response = await http.post(
            url,
            headers: headers ?? _defaultHeaders,
            body: jsonEncode(body),
          );
          break;
        case RequestType.put:
          response = await http.put(
            url,
            headers: headers ?? _defaultHeaders,
            body: jsonEncode(body),
          );
          break;
        case RequestType.delete:
          response = await http.delete(
            url,
            headers: headers ?? _defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
      }

      return _handleResponse(response);
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return jsonDecode(response.body);
      case 201:
        return jsonDecode(response.body);
      case 400:
        throw Exception("Bad Request: ${response.body}");
      case 401:
        throw Exception("Unauthorized: ${response.body}");
      case 403:
        throw Exception("Forbidden: ${response.body}");
      case 404:
        throw Exception("Not Found: ${response.body}");
      case 500:
      default:
        throw Exception(
          "Server Error (${response.statusCode}): ${response.body}",
        );
    }
  }
}
