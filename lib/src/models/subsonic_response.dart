class SubSonicResponse {
  final String _responseKey;
  final Map<String, dynamic> _data;

  Map<String, dynamic> get data =>
      _responseKey != null && isOkay ? _data[_responseKey] : _data;

  String get status => _data['status'];

  String get version => _data['version'];

  bool get isOkay => _data['status'] == "ok";

  SubSonicResponse(this._data, this._responseKey);
}
