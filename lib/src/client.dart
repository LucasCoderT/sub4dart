import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:password_hash/password_hash.dart';
import 'package:sub4dart/src/enums.dart';
import 'package:sub4dart/src/exceptions.dart';
import 'package:sub4dart/src/models/route.dart';
import 'package:sub4dart/src/models/subsonic_response.dart';
import 'package:sub4dart/src/subsonic_api.dart'; // for the utf8.encode method

class SubSonicClient implements SubSonicAPI {
  /// Unique Client ID sent with every request.
  final String _clientID = "Sub4Dartv01";

  /// The Base REST API route used.
  final String _baseRoute = "/rest";

  /// The duration to wait for a request to timeout, defaults to 5 seconds.
  int _timeOut;

  /// General parameters sent with every request.
  Map<String, dynamic> _baseParams;

  /// The url provided in the constructor.
  Uri _path;

  /// The MD5 hash for authentication.
  String _password;

  /// The salt used for authentication.
  String _salt;

  /// The Client used to make requests.
  http.Client _client;

  /// Username of the subsonic user to authenticate with.
  String username;

  SubSonicClient(String path, this.username, String password, {int timeout}) {
    if (!path.startsWith("http")) {
      path = "http://$path";
    }
    this._path = Uri.parse(path);
    this._client = http.Client();
    this._timeOut = timeout ?? 5;

    this._baseParams = {
      "u": this.username,
      "v": "1.16.1",
      "c": _clientID,
      "f": "json",
    };
    _encryptPassword(password);
  }

  /// Generates a salt and encrypts the password per subsonic rules for authenticating.
  void _encryptPassword(String password) {
    var salt = Salt.generateAsBase64String(6);
    var bytes = utf8.encode(password + salt); // data being hashed
    var digest = md5.convert(bytes);
    _password = digest.toString();
    _salt = salt;
  }

  /// Combines any route parameters and builds a [Uri] to represent the final endpoint.
  Uri _buildEndpoint(Route route) {
    Map<String, dynamic> payload = {"t": _password, "s": _salt};
    route.params?.forEach(
            (key, value) =>
        value != null
            ? payload[key] = value.toString()
            : null);
    payload.addAll(_baseParams);
    var endpoint = Uri(
        scheme: _path.scheme.isEmpty ? "http" : _path.scheme,
        host: _path.host,
        port: _path.port ?? 80,
        path: "$_baseRoute${route.endpoint}",
        queryParameters: payload);
    return endpoint;
  }

  /// Requests the data from Subsonic and returns a [SubSonicResponse]
  Future<SubSonicResponse> _request(Route route) async {
    var endpoint = _buildEndpoint(route);
    try {
      http.Response response =
      await _client.get(endpoint).timeout(Duration(seconds: _timeOut));
      if (response.statusCode == 200) {
        if (response.headers['content-type'] ==
            "application/json; charset=UTF-8") {
          var responseData = convert.jsonDecode(response.body);
          SubSonicResponse sonicResponse = SubSonicResponse(
              responseData['subsonic-response'], route.dataKey);
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
                throw RequiresPremium(message, code);
              case 70:
                throw DataNotFoundException(message, code);
              default:
                throw Exception(
                    "Unable to process request: Returned error code ${code} with message: ${message}");
            }
          }
        } else {
          throw Exception("Returned malformed data");
        }
      } else {
        throw Exception("Unable to parse data");
      }
    } on TimeoutException {
      throw Exception("Request timed out");
    }
  }

  /// Used for endpoints that return binary data
  Future<HttpClientResponse> _requestData(Route route) async {
    var endpoint = _buildEndpoint(route);
    HttpClientResponse data = await HttpClient()
        .getUrl(endpoint)
        .timeout(Duration(seconds: _timeOut))
        .then((HttpClientRequest request) => request.close());
    if (data.headers.contentType == ContentType.binary) {
      return data;
    } else if (data.headers.contentType == ContentType.text) {
      throw Exception();
    }
    return null;
  }

  /// Used to test connectivity with the server.
  Future<SubSonicResponse> getPing() async {
    var route = Route("/ping");
    return await _request(route);
  }

  /// Get details about the software license.
  Future<SubSonicResponse> getLicense() async {
    var route = Route("/getLicense");
    return await _request(route);
  }

  /// Returns all configured top-level music folders.
  Future<SubSonicResponse> getMusicFolders() async {
    var route = Route("/getMusicFolders", dataKey: "musicFolders");
    return await _request(route);
  }

  /// Returns an indexed structure of all artists.
  Future<SubSonicResponse> getIndexes(
      [String musicFolderId, String ifModifiedSince]) async {
    var route = Route("/getIndexes", dataKey: "indexes", payload: {
      "musicFolderId": musicFolderId,
      "ifModifiedSince": ifModifiedSince
    });
    return await _request(route);
  }

  /// Returns a listing of all files in a music directory. Typically used to get list of albums for an artist, or list of songs for an album.
  Future<SubSonicResponse> getMusicDirectory(String id) async {
    var route =
    Route("/getMusicDirectory", dataKey: "directory", payload: {"id": id});
    return await _request(route);
  }

  /// Returns all genres.
  Future<SubSonicResponse> getGenres() async {
    var route = Route("/getGenres", dataKey: "genres");
    return await _request(route);
  }

  /// Similar to [getIndexes], but organizes music according to ID3 tags.
  Future<SubSonicResponse> getArtists([String musicFolderId]) async {
    var route = Route("/getArtists",
        dataKey: "artists", payload: {"musicFolderId": musicFolderId});
    return await _request(route);
  }

  /// Returns details for an artist, including a list of albums. This method organizes music according to ID3 tags.
  Future<SubSonicResponse> getArtist(String id) async {
    var route = Route("/getArtist", dataKey: "artist", payload: {"id": id});
    return await _request(route);
  }

  /// Returns details for an album, including a list of songs. This method organizes music according to ID3 tags.
  Future<SubSonicResponse> getAlbum(String id) async {
    var route = Route("/getAlbum", dataKey: "album", payload: {"id": id});
    return await _request(route);
  }

  /// Returns details for a song.
  Future<SubSonicResponse> getSong(String id) async {
    var route = Route("/getSong", dataKey: "song", payload: {"id": id});
    return await _request(route);
  }

  /// Returns all video files.
  Future<SubSonicResponse> getVideos() async {
    var route = Route(
      "/getVideos",
      dataKey: "videos",
    );
    return await _request(route);
  }

  /// Returns details for a video, including information about available audio tracks, subtitles (captions) and conversions.
  Future<SubSonicResponse> getVideoInfo(String id) async {
    var route =
    Route("/getVideoInfo", dataKey: "videoInfo", payload: {"id": id});
    return await _request(route);
  }

  /// Returns artist info with biography, image URLs and similar artists, using data from last.fm.
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

  /// Returns album notes, image URLs etc, using data from last.fm.
  Future<SubSonicResponse> getAlbumInfo(String id,
      {bool useId3 = false}) async {
    var route = Route(useId3 ? "/getAlbumInfo2" : "/getAlbumInfo",
        dataKey: "albumInfo", payload: {"id": id});
    return await _request(route);
  }

  /// Returns a random collection of songs from the given artist and similar artists, using data from last.fm. Typically used for artist radio features.
  Future<SubSonicResponse> getSimilarSongs(String id,
      {int count = 50, bool useId3 = false}) async {
    var route = Route("/getSimilarSongs${useId3 ? '2' : ''}",
        dataKey: "similarSongs${useId3 ? '2' : ''}",
        payload: {"id": id, "count": count});
    return await _request(route);
  }

  /// Returns top songs for the given artist, using data from last.fm.
  Future<SubSonicResponse> getTopSongs(String artist, {int count = 50}) async {
    var route =
    Route("/getTopSongs", dataKey: "topSongs", payload: {"artist": artist});
    return await _request(route);
  }

  /// Returns a list of random, newest, highest rated etc. albums. Similar to the album lists on the home page of the Subsonic web interface.
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

  /// Returns random songs matching the given criteria.
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

  /// Returns songs in a given genre.
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

  /// Returns what is currently being played by all users.
  Future<SubSonicResponse> getNowPlaying() async {
    var route = Route("/getNowPlaying", dataKey: "nowPlaying", payload: null);
    return await _request(route);
  }

  /// Returns starred songs, albums and artists.
  Future<SubSonicResponse> getStarred(
      {String musicFolderId, bool useId3 = false}) async {
    var route = Route(useId3 ? "/getStarred2" : "/getStarred",
        dataKey: useId3 ? "starred2" : "starred",
        payload: {"musicFolderId": musicFolderId});
    return await _request(route);
  }

  /// Returns a listing of files matching the given search criteria. Supports paging through the result.
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

  /// Returns all playlists a user is allowed to play.
  Future<SubSonicResponse> getPlaylists({String username}) async {
    var route = Route("/getPlaylists",
        dataKey: "playlists", payload: {"username": username});
    return await _request(route);
  }

  /// Returns a listing of files in a saved playlist.
  Future<SubSonicResponse> getPlayList(String id) async {
    var route = Route("/getPlayList", dataKey: "playlist", payload: {"id": id});
    return await _request(route);
  }

  /// Creates a playlist
  Future<SubSonicResponse> createPlaylist(String name,
      List<String> songs) async {
    var route = Route("/createPlaylist",
        dataKey: "playlist", payload: {"name": name, "songId": songs});
    return await _request(route);
  }

  /// Updates a playlist. Only the owner of a playlist is allowed to update it.
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

  /// Deletes a saved playlist.
  Future<SubSonicResponse> deletePlaylist(String playlistId) async {
    var route =
    Route("/deletePlaylist", dataKey: null, payload: {"id": playlistId});
    return await _request(route);
  }

  /// Streams a given media file.
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

  /// Downloads a given media file. Similar to [stream], but this method returns the original media data without transcoding or downsampling.
  Future<HttpClientResponse> download(String id) async {
    var route = Route("/download", dataKey: null, payload: {"id": id});
    return await _requestData(route);
  }

  Future<SubSonicResponse> hls() async {
    throw UnimplementedError("hls not implemented");
  }

  /// Returns captions (subtitles) for a video. Use [getVideoInfo] to get a list of available captions.
  Future<SubSonicResponse> getCaptions(String id, {String format}) async {
    var route = Route("/getCaptions",
        dataKey: null, payload: {"id": id, "format": format});
    return await _request(route);
  }

  /// Returns a cover art image.
  Future<HttpClientResponse> getCoverArt(String id, {String size}) async {
    var route =
    Route("/getCoverArt", dataKey: null, payload: {"id": id, "size": size});
    return _requestData(route);
  }

  /// Searches for and returns lyrics for a given song.
  Future<SubSonicResponse> getLyrics({String artist, String title}) async {
    var route = Route("/getLyrics",
        dataKey: "lyrics", payload: {"artist": artist, "title": title});
    return await _request(route);
  }

  /// Returns the avatar (personal image) for a user.
  Future<HttpClientResponse> getAvatar(String username) async {
    var route =
    Route("/getAvatar", dataKey: null, payload: {"username": username});
    return _requestData(route);
  }

  /// Attaches a star to a song, album or artist.
  Future<SubSonicResponse> star(
      {String id, String albumId, String artistId}) async {
    var route = Route("/star",
        dataKey: null,
        payload: {"id": id, "albumId": albumId, "artistId": artistId});
    return await _request(route);
  }

  /// Removes the star from a song, album or artist.
  Future<SubSonicResponse> unstar(
      {String id, String albumId, String artistId}) async {
    var route = Route("/unstar",
        dataKey: null,
        payload: {"id": id, "albumId": albumId, "artistId": artistId});
    return await _request(route);
  }

  /// Sets the rating for a music file.
  Future<SubSonicResponse> setRating(String id, int rating) async {
    var route = Route("/setRating",
        dataKey: null, payload: {"id": id, "rating": rating});
    return await _request(route);
  }

  /// Registers the local playback of one or more media files.
  /// Typically used when playing media that is cached on the client.
  Future<SubSonicResponse> scrobble(String id,
      {DateTime time, bool submission}) async {
    var route = Route("/scrobble",
        dataKey: null,
        payload: {"id": id, "time": time, "submission": submission});
    return await _request(route);
  }

  /// Returns information about shared media this user is allowed to manage.
  Future<SubSonicResponse> getShares() async {
    var route = Route("/getShares", dataKey: "shares", payload: null);
    return await _request(route);
  }

  ///Creates a public URL that can be used by anyone to stream music or video from the Subsonic server.
  ///The URL is short and suitable for posting on Facebook, Twitter etc.
  ///Note: The user must be authorized to share (see Settings > Users > User is allowed to share files with anyone).
  Future<SubSonicResponse> createShare(String id,
      {String description, DateTime expires}) async {
    var route = Route("/createShare", dataKey: "shares", payload: {
      "id": id,
      "description": description,
      "expires": expires.millisecondsSinceEpoch
    });
    return await _request(route);
  }

  /// Updates the description and/or expiration date for an existing share.
  Future<SubSonicResponse> updateShare(String id,
      {String description, DateTime expires}) async {
    var route = Route("/updateShare", dataKey: null, payload: {
      "id": id,
      "description": description,
      "expires": expires.millisecondsSinceEpoch
    });
    return await _request(route);
  }

  /// Deletes an existing share.
  Future<SubSonicResponse> deleteShare(String id) async {
    var route = Route("/deleteShare", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  /// Returns all Podcast channels the server subscribes to, and (optionally) their episodes.
  /// This method can also be used to return details for only one channel - refer to the id parameter.
  /// A typical use case for this method would be to first retrieve all channels without episodes,
  /// and then retrieve all episodes for the single channel the user selects.
  Future<SubSonicResponse> getPodcasts(
      {bool includeEpisodes, String id}) async {
    var route = Route("/getPodcasts",
        dataKey: "podcasts",
        payload: {"includeEpisodes": includeEpisodes, "id": id});
    return await _request(route);
  }

  /// Returns the most recently published Podcast episodes.
  Future<SubSonicResponse> getNewestPodcasts({int count}) async {
    var route = Route("/getNewestPodcasts",
        dataKey: "newstPodcasts", payload: {"count": count});
    return await _request(route);
  }

  /// Requests the server to check for new Podcast episodes.
  /// Note: The user must be authorized for Podcast administration
  /// (see Settings > Users > User is allowed to administrate Podcasts).
  Future<SubSonicResponse> refreshPodcasts() async {
    var route = Route("/refreshPodcasts", dataKey: null, payload: null);
    return await _request(route);
  }

  /// Adds a new Podcast channel. Note: The user must be authorized for Podcast
  /// administration (see Settings > Users > User is allowed to administrate Podcasts).
  Future<SubSonicResponse> createPodcastChannel(String url) async {
    var route =
    Route("/createPodcastChannel", dataKey: null, payload: {"url": url});
    return await _request(route);
  }

  /// Deletes a Podcast channel. Note:
  /// The user must be authorized for Podcast
  /// administration (see Settings > Users > User is allowed to administrate Podcasts).
  Future<SubSonicResponse> deletePodcastChannel(String id) async {
    var route =
    Route("/deletePodcastChannel", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  /// Deletes a Podcast episode.
  Future<SubSonicResponse> deletePodcastEpisode(String id) async {
    var route =
    Route("/deletePodcastEpisode", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  /// Request the server to start downloading a given Podcast episode. Note:
  /// The user must be authorized for Podcast
  /// administration (see Settings > Users > User is allowed to administrate Podcasts).
  Future<SubSonicResponse> downloadPodcastEpisode(String id) async {
    var route =
    Route("/downloadPodcastEpisode", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  /// Controls the jukebox, i.e., playback directly on the server's audio hardware.
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

  /// Returns all internet radio stations.
  Future<SubSonicResponse> getInternetRadioStations() async {
    var route = Route("/getInternetRadioStations",
        dataKey: "internetRadioStations", payload: null);
    return await _request(route);
  }

  /// Adds a new internet radio station.
  /// Only users with admin privileges are allowed to call this method.
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

  /// Updates an existing internet radio station.
  /// Only users with admin privileges are allowed to call this method.
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

  /// Deletes an existing internet radio station.
  /// Only users with admin privileges are allowed to call this method.
  Future<SubSonicResponse> deleteInternetRadioStation(String id) async {
    var route = Route("/deleteInternetRadioStation",
        dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  /// Returns the current visible (non-expired) chat messages.
  Future<SubSonicResponse> getChatMessages({DateTime since}) async {
    var route = Route("/getChatMessages",
        dataKey: "chatMessages",
        payload: {"since": since?.millisecondsSinceEpoch});
    return await _request(route);
  }

  /// Adds a message to the chat log.
  Future<SubSonicResponse> addChatMessage(String message) async {
    var route =
    Route("/addChatMessage", dataKey: null, payload: {"message": message});
    return await _request(route);
  }

  /// Get details about a given user,
  /// including which authorization roles and folder access it has.
  /// Can be used to enable/disable certain features in the client, such as jukebox control.
  Future<SubSonicResponse> getUser(String username) async {
    var route =
    Route("/getUser", dataKey: "user", payload: {"username": username});
    return await _request(route);
  }

  /// Get details about all users,
  /// including which authorization roles and folder access they have.
  /// Only users with admin privileges are allowed to call this method.
  Future<SubSonicResponse> getUsers() async {
    var route = Route("/getUsers", dataKey: "users", payload: null);
    return await _request(route);
  }

  /// Creates a new Subsonic user,
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

  /// Modifies an existing Subsonic user
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

  /// Deletes an existing Subsonic user
  Future<SubSonicResponse> deleteUser(String username) async {
    var route =
    Route("/deleteUser", dataKey: null, payload: {"username": username});
    return await _request(route);
  }

  /// Changes the password of an existing Subsonic user, using the following parameters.
  /// You can only change your own password unless you have admin privileges.
  Future<SubSonicResponse> changePassword(String password,
      {String username}) async {
    var route = Route("/changePassword",
        dataKey: null, payload: {"username": username ?? this.username});
    var response = await _request(route);
    if (response.isOkay) {
      _encryptPassword(password);
    }
    return response;
  }

  /// Returns all bookmarks for this user. A bookmark is a position within a certain media file.
  Future<SubSonicResponse> getBookmarks() async {
    var route = Route("/getBookmarks", dataKey: "bookmarks", payload: null);
    return await _request(route);
  }

  /// Creates or updates a bookmark (a position within a media file).
  /// Bookmarks are personal and not visible to other users.
  Future<SubSonicResponse> createBookmark(String id, int position,
      {String comment}) async {
    var route = Route("/createBookmark",
        dataKey: null,
        payload: {"id": id, "position": position, "comment": comment});
    return await _request(route);
  }

  /// Deletes the bookmark for a given file.
  Future<SubSonicResponse> deleteBookmark(String id) async {
    var route = Route("/deleteBookmark", dataKey: null, payload: {"id": id});
    return await _request(route);
  }

  /// Returns the state of the play queue for this user (as set by [savePlayQueue]).
  /// This includes the tracks in the play queue, the currently playing track, and the position within this track.
  /// Typically used to allow a user to move between different clients/apps while retaining the same play queue
  /// (for instance when listening to an audio book).
  Future<SubSonicResponse> getPlayQueue() async {
    var route = Route("/getPlayQueue", dataKey: "playQueue", payload: null);
    return await _request(route);
  }

  /// Saves the state of the play queue for this user.
  /// This includes the tracks in the play queue, the currently playing track, and the position within this track.
  /// Typically used to allow a user to move between different clients/apps while retaining the same play queue
  /// (for instance when listening to an audio book).
  Future<SubSonicResponse> savePlayQueue(String id,
      {String currentlyPlayingId, int position}) async {
    var route = Route("/savePlayQueue", dataKey: null, payload: {
      "id": id,
      "current": currentlyPlayingId,
      "position": position
    });
    return await _request(route);
  }

  /// Returns the current status for media library scanning.
  Future<SubSonicResponse> getScanStatus() async {
    var route = Route("/getScanStatus", dataKey: "scanStatus", payload: null);
    return await _request(route);
  }

  /// Initiates a rescan of the media libraries.
  Future<SubSonicResponse> startScan() async {
    var route = Route("/startScan", dataKey: "scanStatus", payload: null);
    return await _request(route);
  }

  void dispose() {
    _client.close();
  }
}
