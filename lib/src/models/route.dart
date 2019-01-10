import 'package:sub4dart/src/models/endpoint.dart';

class Route implements EndPoint {
  var endpoint;
  var params;

  Route(String endpoint, [Map<String, dynamic> params]) {
    this.endpoint = endpoint;
    this.params = params ?? {};
  }

  @override
  Uri get(Uri url) {
    var ep = Uri.parse(url.toString() + endpoint);
    params.addAll(ep.queryParameters);
    ep.replace(queryParameters: params);
    return ep;
  }
}
