class SubSonicResponse {
  /// The nested key to allow for easier lookup of data.
  final String _responseKey;

  /// The data returned by Subsonic.
  final Map<String, dynamic> _data;

  /// Uses the [_responseKey] if applicable to get the actual data.
  Map<String, dynamic> get data =>
      _responseKey != null && isOkay ? _data[_responseKey] : _data;

  /// Get the status of the response.
  String get status => _data['status'];

  /// Gets the server rest api version.
  String get version => _data['version'];

  /// Checks if the Response was successful.
  bool get isOkay => _data['status'] == "ok";

  SubSonicResponse(this._data, this._responseKey);
}
