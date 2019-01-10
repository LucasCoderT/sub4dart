abstract class EndPoint {
  String endpoint;
  Map<String, dynamic> params;

  Uri get(Uri url);
}
