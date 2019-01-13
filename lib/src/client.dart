import 'dart:convert' as convert;
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:password_hash/password_hash.dart';
import 'package:sub4dart/src/models/route.dart'; // for the utf8.encode method

class SubSonic {
  final String _clientID = "Sub4Dartv01";
  final String _baseRoute = "/rest";
  Map<String, dynamic> _baseParams;
  Uri _path;
  String _password;
  http.Client _client;

  SubSonic(String path, username, this._password) {
    if (!path.startsWith("http")) {
      path = "http://$path";
    }
    this._path = Uri.parse(path);
    this._client = http.Client();
    this._baseParams = {
      "u": username,
      "v": "1.16.1",
      "c": _clientID,
      "f": "json",
    };
  }

  void changePassword(String newPassword) {
    _password = newPassword;
  }

  Map<String, String> _encryptPassword() {
    var salt = Salt.generateAsBase64String(6);
    var bytes = utf8.encode(_password + salt); // data being hashed
    var digest = md5.convert(bytes);
    return {"t": digest.toString(), "s": salt};
  }

  Future<bool> isValid() async {
    // TODO
    return true;
  }

  Future<Map<String, dynamic>> _request(Route route) async {
    Map<String, dynamic> payload = {};
    payload.addAll(route.params);
    payload.addAll(_baseParams);
    payload.addAll(_encryptPassword());
    var endpoint = Uri(
        scheme: _path.scheme.isEmpty ? "http" : _path.scheme,
        host: _path.host,
        port: _path.port ?? "80",
        path: "$_baseRoute${route.endpoint}",
        queryParameters: payload);
    http.Response response = await _client.get(endpoint);
    if (response.statusCode == 200) {
      return convert.jsonDecode(response.body);
    } else {
      throw Exception("Unable to parse data");
    }
  }

  Future<bool> getPing() async {
    var route = Route("/ping");
    try {
      await _request(route);
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
