import 'package:sub4dart/src/models/subsonic_response.dart';
import 'package:sub4dart/sub4dart.dart';

main() async {
  var subsonic = new SubSonicClient("https://music.example.com", "John", "Doe");
  SubSonicResponse response = await subsonic.getPing();
  print(response.isOkay);
}
