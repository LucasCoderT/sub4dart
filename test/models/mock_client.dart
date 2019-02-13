import 'dart:io';

import 'package:sub4dart/src/models/route.dart';
import 'package:sub4dart/src/models/subsonic_response.dart';
import 'package:sub4dart/sub4dart.dart';

class MockClient extends SubSonicClient {
  MockClient(String path, String username, String password, {int timeout})
      : super(path, username, password, timeout: timeout);

  @override
  Future<SubSonicResponse> _request(Route route) async {
    return SubSonicResponse({"static": "ok"}, null);
  }

  @override
  Future<HttpClientResponse> _requestData(Route route) async {
    // TODO: implement _requestData
    return null;
  }
}
