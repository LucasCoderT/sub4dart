import 'package:http/http.dart' as http;
import 'package:sub4dart/src/models/route.dart';
import 'dart:convert' as convert;

class SubSonic {
  final String clientID = "Sub4Dart 0.1";
  final String baseRoute = "/rest";
  Uri path;
  String password, _salt;
  http.Client client;

  SubSonic(String path, username, password) {
    this.path = Uri.parse(path);
    this.password = _encryptPassword(password);
    this.client = http.Client();
    this.path.replace(queryParameters: {
      "u": username,
      "t": null,
      "s": null,
      "v": "1.16.1",
      "c": clientID,
      "f": "json",
    });
  }

  String _encryptPassword(String rawPassword) {
    
  }

  Future<bool> isValid() async {
    // TODO
    return true;
  }

  Future<Map<String, dynamic>> get(Route route) async {
    http.Response response = await client.get(route.get(path));
    if (response.statusCode == 200) {
      return convert.jsonDecode(response.body);
    } else {
      throw Exception("Unable to parse data");
    }
  }

  Future<bool> getPing() async {
    var route = Route("/ping");
    try {
      await get(route);
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    client.close();
  }
}
