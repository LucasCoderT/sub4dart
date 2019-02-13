import 'dart:io';

import 'package:sub4dart/src/enums.dart';
import 'package:sub4dart/src/models/subsonic_response.dart';

abstract class SubSonicAPI {
  Future<SubSonicResponse> getPing();

  Future<SubSonicResponse> getLicense();

  Future<SubSonicResponse> getMusicFolders();

  Future<SubSonicResponse> getIndexes(
      [String musicFolderId, String ifModifiedSince]);

  Future<SubSonicResponse> getMusicDirectory(String id);

  Future<SubSonicResponse> getGenres();

  Future<SubSonicResponse> getArtists([String musicFolderId]);

  Future<SubSonicResponse> getArtist(String id);

  Future<SubSonicResponse> getAlbum(String id);

  Future<SubSonicResponse> getSong(String id);

  Future<SubSonicResponse> getVideos();

  Future<SubSonicResponse> getVideoInfo(String id);

  Future<SubSonicResponse> getArtistInfo(String id,
      {String count, bool includeNotPresent, bool useId3 = false});

  Future<SubSonicResponse> getAlbumInfo(String id, {bool useId3 = false});

  Future<SubSonicResponse> getSimilarSongs(String id,
      {int count = 50, bool useId3 = false});

  Future<SubSonicResponse> getTopSongs(String artist, {int count = 50});

  Future<SubSonicResponse> getAlbumList(SearchType type,
      {int size,
      int offset,
      DateTime fromYear,
      DateTime toYear,
      String genre,
      String musicFolderId,
      bool useId3 = false});

  Future<SubSonicResponse> getRandomSongs(
      {int size,
      String genre,
      DateTime fromYear,
      DateTime toYear,
      String musicFolderId});

  Future<SubSonicResponse> getSongsByGenre(String genre,
      {int count = 10, int offset = 0, String musicFolderId});

  Future<SubSonicResponse> getNowPlaying();

  Future<SubSonicResponse> getStarred(
      {String musicFolderId, bool useId3 = false});

  Future<SubSonicResponse> search(String query,
      {int artistCount,
      int artistOffset,
      int albumCount,
      int albumOffset,
      int songCount,
      int songOffset,
      String musicFolderId,
      bool useId3 = false});

  Future<SubSonicResponse> getPlaylists({String username});

  Future<SubSonicResponse> getPlayList(String id);

  Future<SubSonicResponse> createPlaylist(String name, List<String> songs);

  Future<SubSonicResponse> updatePlaylist(String id,
      {String name,
      String comment,
      bool public,
      List<String> songstoAdd,
      List<int> songIndexesToRemove});

  Future<SubSonicResponse> deletePlaylist(String playlistId);

  Future<HttpClientResponse> stream(String id,
      {String maxBitRate,
      String format,
      int timeOffset,
      String resolution,
      bool estimateContentLength = false,
      bool converted = false});

  Future<HttpClientResponse> download(String id);

  Future<SubSonicResponse> hls();

  Future<SubSonicResponse> getCaptions(String id, {String format});

  Future<HttpClientResponse> getCoverArt(String id, {String size});

  Future<SubSonicResponse> getLyrics({String artist, String title});

  Future<HttpClientResponse> getAvatar(String username);

  Future<SubSonicResponse> star({String id, String albumId, String artistId});

  Future<SubSonicResponse> unstar({String id, String albumId, String artistId});

  Future<SubSonicResponse> setRating(String id, int rating);

  Future<SubSonicResponse> scrobble(String id,
      {DateTime time, bool submission});

  Future<SubSonicResponse> getShares();

  Future<SubSonicResponse> createShare(String id,
      {String description, DateTime expires});

  Future<SubSonicResponse> updateShare(String id,
      {String description, DateTime expires});

  Future<SubSonicResponse> deleteShare(String id);

  Future<SubSonicResponse> getPodcasts({bool includeEpisodes, String id});

  Future<SubSonicResponse> getNewestPodcasts({int count});

  Future<SubSonicResponse> refreshPodcasts();

  Future<SubSonicResponse> createPodcastChannel(String url);

  Future<SubSonicResponse> deletePodcastChannel(String id);

  Future<SubSonicResponse> deletePodcastEpisode(String id);

  Future<SubSonicResponse> downloadPodcastEpisode(String id);

  Future<SubSonicResponse> jukeboxControl(JukeBoxAction action,
      {int index, int offset, String id, int gain});

  Future<SubSonicResponse> getInternetRadioStations();

  Future<SubSonicResponse> createInternetRadioStation(
      String streamUrl, String name,
      {String homepageUrl});

  Future<SubSonicResponse> updateInternetRadioStation(
      String id, String streamUrl, String name,
      {String homepageUrl});

  Future<SubSonicResponse> deleteInternetRadioStation(String id);

  Future<SubSonicResponse> getChatMessages({DateTime since});

  Future<SubSonicResponse> addChatMessage(String message);

  Future<SubSonicResponse> getUser(String username);

  Future<SubSonicResponse> getUsers();

  Future<SubSonicResponse> createUser(
      String username, String password, String email,
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
      List<String> musicFolders});

  Future<SubSonicResponse> updateUser(
      String username, String password, String email,
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
      int maxBitRate});

  Future<SubSonicResponse> deleteUser(String username);

  Future<SubSonicResponse> changePassword(String password, {String username});

  Future<SubSonicResponse> getBookmarks();

  Future<SubSonicResponse> createBookmark(String id, int position,
      {String comment});

  Future<SubSonicResponse> deleteBookmark(String id);

  Future<SubSonicResponse> getPlayQueue();

  Future<SubSonicResponse> savePlayQueue(String id,
      {String currentlyPlayingId, int position});

  Future<SubSonicResponse> getScanStatus();

  Future<SubSonicResponse> startScan();
}
