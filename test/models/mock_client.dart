import 'dart:async';
import 'dart:io';

import 'package:sub4dart/src/models/route.dart';
import 'package:sub4dart/src/models/subsonic_response.dart';
import 'package:sub4dart/sub4dart.dart';

class MockClient extends SubSonicClient {
  MockClient(String path, String username, String password, {int timeout})
      : super(path, username, password, timeout: timeout);

  @override
  Future<SubSonicResponse> request(Route route) async {
    return SubSonicResponse({"status": "ok"}, null);
  }

  @override
  Future<HttpClientResponse> requestData(Route route) {
    // TODO: implement requestData
    return null;
  }
}
