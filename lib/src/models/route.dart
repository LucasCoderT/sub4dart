import 'package:sub4dart/src/models/endpoint.dart';

class Route implements EndPoint {
  var endpoint;
  var params;

  Route(String endpoint, [Map<String, dynamic> payload]) {
    this.endpoint = endpoint;
    this.params = payload ?? {};
  }
}
