import 'package:sub4dart/sub4dart.dart';
import 'package:test/test.dart';

void main() {
  group("REST Tests", () {
    SubSonicClient subSonic;

    setUpAll(() {
      subSonic = new SubSonicClient("https://test.com", "lucas", "password");
    });

    test("Change Credentials ", () async {
      subSonic.changeSettings(username: "lucas", host: "testhost");
    });

    test("Get Ping", () async {
      var data = await subSonic.getPing();
      expect(data.isOkay, isTrue);
    });

    test("Get License", () async {
      var data = await subSonic.getLicense();
      expect(data.isOkay, isTrue);
    });

    test("Get Music Folders", () async {
      var data = await subSonic.getMusicFolders();
      expect(data.isOkay, isTrue);
    });

    test("Get Indexes", () async {
      var data = await subSonic.getIndexes();
      expect(data.isOkay, isTrue);
    });

    test("Get Music Directory", () async {
      try {
        var data = await subSonic.getMusicDirectory("1");
        expect(data.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }
    });

    test("Get Genres", () async {
      var data = await subSonic.getGenres();
      expect(data.isOkay, isTrue);
    });

    test("Get Artists", () async {
      var data = await subSonic.getArtists();
      expect(data.isOkay, isTrue);
    });

    test("Get Artist", () async {
      try {
        var data = await subSonic.getArtist("1");
        expect(data.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }
    });

    test("Get Album", () async {
      try {
        var data = await subSonic.getAlbum("1");
        expect(data.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }
    });

    test("Get Song", () async {
      try {
        var data = await subSonic.getSong("1");
        expect(data.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }
    });

    test("Get Videos", () async {
      var data = await subSonic.getVideos();
      expect(data.isOkay, isTrue);
    });

    test("Get Video Info", () async {
      try {
        var data = await subSonic.getVideoInfo("1");
        expect(data.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }
    });

    test("Get Artist Info", () async {
      try {
        var data = await subSonic.getArtistInfo("1");
        expect(data.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }

      try {
        var data2 = await subSonic.getArtistInfo("1", useId3: true);
        expect(data2.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }
    });

    test("Get Album Info", () async {
      try {
        var data = await subSonic.getAlbumInfo("1");
        expect(data.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }
    });

    test("Get Similar Songs", () async {
      try {
        var data = await subSonic.getSimilarSongs("1");
        expect(data.isOkay, isTrue);
      } on DataNotFoundException catch (e) {
        expect(e.code, equals(70));
      }
    });

    test("Get Top Songs", () async {
      var data = await subSonic.getTopSongs("Linkin Park");
      expect(data.isOkay, isTrue);
    });

    test("Get Album List", () async {
      var data = await subSonic.getAlbumList(SearchType.random);
      expect(data.isOkay, isTrue);
    });

    test("Get Random Songs", () async {
      var data = await subSonic.getRandomSongs();
      expect(data.isOkay, isTrue);
    });

    test("Get Songs By Genre", () async {
      var data = await subSonic.getSongsByGenre("rock");
      expect(data.isOkay, isTrue);
    });

    test("Get Now Playing", () async {
      var data = await subSonic.getNowPlaying();
      expect(data.isOkay, isTrue);
    });

    test("Get Starred", () async {
      var data = await subSonic.getStarred();
      expect(data.isOkay, isTrue);
    });

    test("Search", () async {
      var data = await subSonic.search("Linkin Park");
      expect(data.isOkay, isTrue);
    });

    test("Get Playlists", () async {
      var data = await subSonic.getPlaylists();
      expect(data.isOkay, isTrue);
      expect(data.data, isNotEmpty);
    });

    tearDown(() => subSonic.dispose());
  });
}
