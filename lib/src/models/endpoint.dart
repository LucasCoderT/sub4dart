abstract class EndPoint {
  /// The endpoint this instance is for.
  String endpoint;

  /// Any additional parameters that this [EndPoint] needs.
  Map<String, dynamic> params;

  /// The nested key name. null if this [EndPoint] does not have any.
  String dataKey;
}
