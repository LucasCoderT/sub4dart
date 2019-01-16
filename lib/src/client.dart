import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:password_hash/password_hash.dart';
import 'package:sub4dart/src/enums.dart';
import 'package:sub4dart/src/exceptions.dart';
import 'package:sub4dart/src/models/route.dart';
import 'package:sub4dart/src/models/subsonic_response.dart'; // for the utf8.encode method

class SubSonic {
  final String _clientID = "Sub4Dartv01";
  final String _baseRoute = "/rest";
  Map<String, dynamic> _baseParams;
  Uri _path;
  String _password;
  http.Client _client;
  String username;

  SubSonic(String path, username, this._password) {
    if (!path.startsWith("http")) {
      path = "http://$path";
    }
    this.username = username;
    this._path = Uri.parse(path);
    this._client = http.Client();
    this._baseParams = {
      "u": this.username,
      "v": "1.16.1",
      "c": _clientID,
      "f": "json",
    };
  }

  Map<String, String> _encryptPassword() {
    var salt = Salt.generateAsBase64String(6);
    var bytes = utf8.encode(_password + salt); // data being hashed
    var digest = md5.convert(bytes);
    return {"t": digest.toString(), "s": salt};
  }

  Uri _buildEndpoint(Route route) {
    Map<String, dynamic> payload = {};
    route.params?.forEach(
            (key, value) =>
        value != null
            ? payload[key] = value.toString()
            : null);
    payload.addAll(_baseParams);
    payload.addAll(_encryptPassword());
    var endpoint = Uri(
        scheme: _path.scheme.isEmpty ? "http" : _path.scheme,
        host: _path.host,
        port: _path.port ?? 80,
        path: "$_baseRoute${route.endpoint}",
        queryParameters: payload);
    return endpoint;
  }

  Future<SubSonicResponse> _request(Route route) async {
    var endpoint = _buildEndpoint(route);
    http.Response response = await _client.get(endpoint);
    if (response.statusCode == 200) {
      if (response.headers['content-type'] ==
          "application/json; charset=UTF-8") {
        var responseData = convert.jsonDecode(response.body);
        SubSonicResponse sonicResponse =
        SubSonicResponse(responseData['subsonic-response'], route.dataKey);
        if (sonicResponse.isOkay) {
          return sonicResponse;
        } else {
          var errorData = sonicResponse.data['error'];
          var message = errorData['message'];
          var code = errorData['code'];
          switch (code) {
            case 0:
              throw BaseException(message, code);
            case 10:
              throw MissingRequiredArgument(message, code);
            case 20:
              throw ClientOutOfDate(message, code);
            case 30:
              throw ServerOutOfDate(message, code);
            case 40:
              throw InvalidCredentials(message, code);
            case 41:
              throw LDAPNotSupported(message, code);
            case 50:
              throw UnAuthorized(message, code);
            case 60:
              throw RequiresPermiumn(message, code);
            case 70:
              throw DataNotFoundException(message, code);
            default:
              throw Exception(
                  "Unable to process request: Returned error code ${code} with message: ${message}");
          }
        }
      } else {
        throw Exception();
      }
    } else {
      throw Exception("Unable to parse data");
    }
  }

  Future<HttpClientResponse> _requestData(Route route) async {
    var endpoint = _buildEndpoint(route);
    HttpClientResponse data = await HttpClient()
        .getUrl(endpoint)
        .then((HttpClientRequest request) => request.close());
    if (data.headers.contentType == ContentType.binary) {
      return data;
    } else if (data.headers.contentType == ContentType.text) {
      throw Exception();
    }
    return null;
  }

  Future<SubSonicResponse> getPing() async {
    var route = Route("/ping");
    return await _request(route);
  }

  Future<SubSonicResponse> getLicense() async {
    var route = Route("/getLicense");
    return await _request(route);
  }

  Future<SubSonicResponse> getMusicFolders() async {
    var route = Route("/getMusicFolders", dataKey: "musicFolders");
    return await _request(route);
  }

  Future<SubSonicResponse> getIndexes(
      [String musicFolderId, String ifModifiedSince]) async {
    var route = Route("/getIndexes", dataKey: "indexes", payload: {
      "musicFolderId": musicFolderId,
      "ifModifiedSince": ifModifiedSince
    });
    return await _request(route);
  }

  Future<SubSonicResponse> getMusicDirectory(String id) async {
    var route =
    Route("/getMusicDirectory", dataKey: "directory", payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getGenres() async {
    var route = Route("/getGenres", dataKey: "genres");
    return await _request(route);
  }

  Future<SubSonicResponse> getArtists([String musicFolderId]) async {
    var route = Route("/getArtists",
        dataKey: "artists", payload: {"musicFolderId": musicFolderId});
    return await _request(route);
  }

  Future<SubSonicResponse> getArtist(String id) async {
    var route = Route("/getArtist", dataKey: "artist", payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getAlbum(String id) async {
    var route = Route("/getAlbum", dataKey: "album", payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getSong(String id) async {
    var route = Route("/getSong", dataKey: "song", payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getVideos() async {
    var route = Route(
      "/getVideos",
      dataKey: "videos",
    );
    return await _request(route);
  }

  Future<SubSonicResponse> getVideoInfo(String id) async {
    var route =
    Route("/getVideoInfo", dataKey: "videoInfo", payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getArtistInfo(String id,
      {String count, bool includeNotPresent, bool useId3 = false}) async {
    var route = Route(useId3 ? "/getArtistInfo2" : "/getArtistInfo",
        dataKey: useId3 ? "artistInfo2" : "artistInfo",
        payload: {
          "id": id,
          "count": count,
          "includeNotPresent": includeNotPresent
        });
    return await _request(route);
  }

  Future<SubSonicResponse> getAlbumInfo(String id,
      {bool useId3 = false}) async {
    var route = Route(useId3 ? "/getAlbumInfo2" : "/getAlbumInfo",
        dataKey: "albumInfo", payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getSimilarSongs(String id,
      {int count = 50, bool useId3 = false}) async {
    var route = Route("/getSimilarSongs${useId3 ? '2' : ''}",
        dataKey: "similarSongs${useId3 ? '2' : ''}",
        payload: {"id": id, "count": count});
    return await _request(route);
  }

  Future<SubSonicResponse> getTopSongs(String artist, {int count = 50}) async {
    var route =
    Route("/getTopSongs", dataKey: "topSongs", payload: {"artist": artist});
    return await _request(route);
  }

  Future<SubSonicResponse> getAlbumList(SearchType type,
      {int size,
        int offset,
        DateTime fromYear,
        DateTime toYear,
        String genre,
        String musicFolderId,
        bool useId3 = false}) async {
    var route = Route(useId3 ? "/getAlbumList2" : "/getAlbumList",
        dataKey: useId3 ? "albumList2" : "albumList",
        payload: {
          "type": searchTypeToString(type),
          "size": size,
          "offset": offset,
          "fromYear": fromYear,
          "toYear": toYear,
          "genre": genre,
          "musicFolderId": musicFolderId
        });
    return await _request(route);
  }

  Future<SubSonicResponse> getRandomSongs({int size,
    String genre,
    DateTime fromYear,
    DateTime toYear,
    String musicFolderId}) async {
    var route = Route("/getRandomSongs", dataKey: "randomSongs", payload: {
      "size": size,
      "genre": genre,
      "fromYear": fromYear,
      "toYear": toYear,
      "musicFolderId": musicFolderId
    });
    return await _request(route);
  }

  Future<SubSonicResponse> getSongsByGenre(String genre,
      {int count = 10, int offset = 0, String musicFolderId}) async {
    var route = Route("/getSongsByGenre", dataKey: "songsByGenre", payload: {
      "genre": genre,
      "count": count,
      "offset": offset,
      "musicFolderId": musicFolderId
    });
    return await _request(route);
  }

  Future<SubSonicResponse> getNowPlaying() async {
    var route = Route("/getNowPlaying", dataKey: "nowPlaying", payload: null);
    return await _request(route);
  }

  Future<SubSonicResponse> getStarred(
      {String musicFolderId, bool useId3 = false}) async {
    var route = Route(useId3 ? "/getStarred2" : "/getStarred",
        dataKey: useId3 ? "starred2" : "starred",
        payload: {"musicFolderId": musicFolderId});
    return await _request(route);
  }

  Future<SubSonicResponse> search(String query,
      {int artistCount,
        int artistOffset,
        int albumCount,
        int albumOffset,
        int songCount,
        int songOffset,
        String musicFolderId,
        bool useId3 = false}) async {
    var route = Route("/search${useId3 ? '3' : '2'}",
        dataKey: "searchResult${useId3 ? '3' : '2'}",
        payload: {
          "query": query,
          "artistCount": artistCount,
          "artistOffset": artistOffset,
          "albumCount": albumCount,
          "albumOffset": albumOffset,
          "songCount": songCount,
          "songOffset": songOffset,
          "musicFolderId": musicFolderId
        });
    return await _request(route);
  }

  Future<SubSonicResponse> getPlaylists({String username}) async {
    var route = Route("/getPlaylists",
        dataKey: "playlists", payload: {"username": username});
    return await _request(route);
  }

  Future<SubSonicResponse> getPlayList(String id) async {
    var route = Route("/getPlayList", dataKey: "playlist", payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> createPlaylist(String name,
      List<String> songs) async {
    var route = Route("/createPlaylist",
        dataKey: "playlist", payload: {"name": name, "songId": songs});
    return await _request(route);
  }

  Future<SubSonicResponse> updatePlaylist(String id,
      {String name,
        String comment,
        bool public,
        List<String> songstoAdd,
        List<int> songIndexesToRemove}) async {
    var route = Route("/updatePlaylist", dataKey: null, payload: {
      "playlistId": id,
      "name": name,
      "comment": comment,
      "public": public,
      "songIdToAdd": songstoAdd,
      "songIndexToRemove": songIndexesToRemove
    });
    return await _request(route);
  }

  Future<SubSonicResponse> deletePlaylist(String playlistId) async {
    var route =
    Route("/deletePlaylist", dataKey: null, payload: {"id": playlistId});
    return await _request(route);
  }

  Future<HttpClientResponse> stream(String id,
      {String maxBitRate,
        String format,
        int timeOffset,
        String resolution,
        bool estimateContentLength = false,
        bool converted = false}) async {
    var route = Route("/stream", dataKey: null, payload: {
      "id": id,
      "maxBitRate": maxBitRate,
      "formate": format,
      "timeOffset": timeOffset,
      "size": resolution,
      "estimateContentLength": estimateContentLength,
      "converted": converted
    });
    return _requestData(route);
  }

  Future<SubSonicResponse> hls() async {
    // TODO
    return null;
//    var route = Route("/hls", dataKey: null, payload: null);
//    throw Exception("Not Implemented");
////    return await _request(route);
  }

  Future<SubSonicResponse> getCaptions(String id, {String format}) async {
    var route = Route("/getCaptions",
        dataKey: null, payload: {"id": id, "format": format});
    return await _request(route);
  }

  Future<HttpClientResponse> getCoverArt(String id, {String size}) async {
    var route =
    Route("/getCoverArt", dataKey: null, payload: {"id": id, "size": size});
    return _requestData(route);
  }

  Future<SubSonicResponse> getLyrics({String artist, String title}) async {
    var route = Route("/getLyrics",
        dataKey: "lyrics", payload: {"artist": artist, "title": title});
    return await _request(route);
  }

  Future<HttpClientResponse> getAvatar(String username) async {
    var route =
    Route("/getAvatar", dataKey: null, payload: {"username": username});
    return _requestData(route);
  }

  Future<SubSonicResponse> star(
      {String id, String albumId, String artistId}) async {
    var route = Route("/star",
        dataKey: null,
        payload: {"id": id, "albumId": albumId, "artistId": artistId});
    return await _request(route);
  }

  Future<SubSonicResponse> unstar(
      {String id, String albumId, String artistId}) async {
    var route = Route("/unstar",
        dataKey: null,
        payload: {"id": id, "albumId": albumId, "artistId": artistId});
    return await _request(route);
  }

  Future<SubSonicResponse> setRating(String id, int rating) async {
    var route = Route("/setRating",
        dataKey: null, payload: {"id": id, "rating": rating});
    return await _request(route);
  }

  Future<SubSonicResponse> scrobble(String id,
      {DateTime time, bool submission}) async {
    var route = Route("/scrobble",
        dataKey: null,
        payload: {"id": id, "time": time, "submission": submission});
    return await _request(route);
  }

  Future<SubSonicResponse> getShares() async {
    var route = Route("/getShares", dataKey: "shares", payload: null);
    return await _request(route);
  }

  Future<SubSonicResponse> createShare(String id,
      {String description, DateTime expires}) async {
    var route = Route("/createShare", dataKey: "shares", payload: {
      "id": id,
      "description": description,
      "expires": expires.millisecondsSinceEpoch
    });
    return await _request(route);
  }

  Future<SubSonicResponse> updateShare(String id,
      {String description, DateTime expires}) async {
    var route = Route("/updateShare", dataKey: null, payload: {
      "id": id,
      "description": description,
      "expires": expires.millisecondsSinceEpoch
    });
    return await _request(route);
  }

  Future<SubSonicResponse> deleteShare(String id) async {
    var route = Route("/deleteShare", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getPodcasts(
      {bool includeEpisodes, String id}) async {
    var route = Route("/getPodcasts",
        dataKey: "podcasts",
        payload: {"includeEpisodes": includeEpisodes, "id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getNewestPodcasts({int count}) async {
    var route = Route("/getNewestPodcasts",
        dataKey: "newstPodcasts", payload: {"count": count});
    return await _request(route);
  }

  Future<SubSonicResponse> refreshPodcasts() async {
    var route = Route("/refreshPodcasts", dataKey: null, payload: null);
    return await _request(route);
  }

  Future<SubSonicResponse> createPodcastChannel(String url) async {
    var route =
    Route("/createPodcastChannel", dataKey: null, payload: {"url": url});
    return await _request(route);
  }

  Future<SubSonicResponse> deletePodcastChannel(String id) async {
    var route =
    Route("/deletePodcastChannel", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> deletePodcastEpisode(String id) async {
    var route =
    Route("/deletePodcastEpisode", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> downloadPodcastEpisode(String id) async {
    var route =
    Route("/downloadPodcastEpisode", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> jukeboxControl(JukeBoxAction action,
      {int index, int offset, String id, int gain}) async {
    var route = Route("/jukeboxControl",
        dataKey:
        action == JukeBoxAction.get ? "jukeboxPlaylist" : "jukeboxStatus",
        payload: {
          "action": jukeBoxActionToString(action),
          "index": index,
          "offset": offset,
          "id": id,
          "gain": gain
        });

    return await _request(route);
  }

  Future<SubSonicResponse> getInternetRadioStations() async {
    var route = Route("/getInternetRadioStations",
        dataKey: "internetRadioStations", payload: null);
    return await _request(route);
  }

  Future<SubSonicResponse> createInternetRadioStation(String streamUrl,
      String name,
      {String homepageUrl}) async {
    var route = Route("/createInternetRadioStation", dataKey: null, payload: {
      "streamUrl": streamUrl,
      "name": name,
      "homepageUrl": homepageUrl
    });
    return await _request(route);
  }

  Future<SubSonicResponse> updateInternetRadioStation(String id,
      String streamUrl, String name,
      {String homepageUrl}) async {
    var route = Route("/updateInternetRadioStation", dataKey: null, payload: {
      "id": id,
      "streamUrl": streamUrl,
      "name": name,
      "homepageUrl": homepageUrl
    });
    return await _request(route);
  }

  Future<SubSonicResponse> deleteInternetRadioStation(String id) async {
    var route = Route("/deleteInternetRadioStation",
        dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getChatMessages({DateTime since}) async {
    var route = Route("/getChatMessages",
        dataKey: "chatMessages",
        payload: {"since": since?.millisecondsSinceEpoch});
    return await _request(route);
  }

  Future<SubSonicResponse> addChatMessage(String message) async {
    var route =
    Route("/addChatMessage", dataKey: null, payload: {"message": message});
    return await _request(route);
  }

  Future<SubSonicResponse> getUser(String username) async {
    var route =
    Route("/getUser", dataKey: "user", payload: {"username": username});
    return await _request(route);
  }

  Future<SubSonicResponse> getUsers() async {
    var route = Route("/getUsers", dataKey: "users", payload: null);
    return await _request(route);
  }

  Future<SubSonicResponse> createUser(String username, String password,
      String email,
      {bool ldapAuthenticated = false,
        bool adminRole = false,
        bool settingsRole = true,
        bool streamRole = true,
        bool jukeboxRole = false,
        bool downloadRole = false,
        bool uploadRole = false,
        bool playlistRole = false,
        bool coverArtRole = false,
        bool commentRole = false,
        bool podcastRole = false,
        bool shareRole = false,
        bool videoConversionRole = false,
        List<String> musicFolders}) async {
    var route = Route("/createUser", dataKey: null, payload: {
      "username": username,
      "password": password,
      "email": email,
      "ldapAuthenticated": ldapAuthenticated,
      "adminRole": adminRole,
      "settingsRole": settingsRole,
      "streamRole": streamRole,
      "jukeboxRole": jukeboxRole,
      "downloadRole": downloadRole,
      "uploadRole": uploadRole,
      "playlistRole": playlistRole,
      "coverArtRole": coverArtRole,
      "commentRole": commentRole,
      "podcastRole": podcastRole,
      "shareRole": shareRole,
      "videoConversionRole": videoConversionRole,
      "musicFolderId": musicFolders
    });
    return await _request(route);
  }

  Future<SubSonicResponse> updateUser(String username, String password,
      String email,
      {bool ldapAuthenticated = false,
        bool adminRole = false,
        bool settingsRole = true,
        bool streamRole = true,
        bool jukeboxRole = false,
        bool downloadRole = false,
        bool uploadRole = false,
        bool playlistRole = false,
        bool coverArtRole = false,
        bool commentRole = false,
        bool podcastRole = false,
        bool shareRole = false,
        bool videoConversionRole = false,
        List<String> musicFolders,
        int maxBitRate}) async {
    var route = Route("/updateUser", dataKey: null, payload: {
      "username": username,
      "password": password,
      "email": email,
      "ldapAuthenticated": ldapAuthenticated,
      "adminRole": adminRole,
      "settingsRole": settingsRole,
      "streamRole": streamRole,
      "jukeboxRole": jukeboxRole,
      "downloadRole": downloadRole,
      "uploadRole": uploadRole,
      "playlistRole": playlistRole,
      "coverArtRole": coverArtRole,
      "commentRole": commentRole,
      "podcastRole": podcastRole,
      "shareRole": shareRole,
      "videoConversionRole": videoConversionRole,
      "musicFolderId": musicFolders,
      "maxBitRate": maxBitRate
    });
    return await _request(route);
  }

  Future<SubSonicResponse> deleteUser(String username) async {
    var route =
    Route("/deleteUser", dataKey: null, payload: {"username": username});
    return await _request(route);
  }

  Future<SubSonicResponse> changePassword(String password,
      {String username}) async {
    _password = password;
    var route = Route("/changePassword",
        dataKey: null, payload: {"username": username ?? this.username});
    return await _request(route);
  }

  Future<SubSonicResponse> getBookmarks() async {
    var route = Route("/getBookmarks", dataKey: "bookmarks", payload: null);
    return await _request(route);
  }

  Future<SubSonicResponse> createBookmark(String id, int position,
      {String comment}) async {
    var route = Route("/createBookmark",
        dataKey: null,
        payload: {"id": id, "position": position, "comment": comment});
    return await _request(route);
  }

  Future<SubSonicResponse> deleteBookmark(String id) async {
    var route = Route("/deleteBookmark", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  Future<SubSonicResponse> getPlayQueue() async {
    var route = Route("/getPlayQueue", dataKey: "playQueue", payload: null);
    return await _request(route);
  }

  Future<SubSonicResponse> savePlayQueue(String id,
      {String currentlyPlayingId, int position}) async {
    var route = Route("/savePlayQueue", dataKey: null, payload: {
      "id": id,
      "current": currentlyPlayingId,
      "position": position
    });
    return await _request(route);
  }

  Future<SubSonicResponse> getScanStatus() async {
    var route = Route("/getScanStatus", dataKey: "scanStatus", payload: null);
    return await _request(route);
  }

  Future<SubSonicResponse> startScan() async {
    var route = Route("/startScan", dataKey: "scanStatus", payload: null);
    return await _request(route);
  }

  void dispose() {
    _client.close();
  }
}
