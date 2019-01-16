enum SearchType {
  random,
  newest,
  highest,
  frequent,
  recent,
  alphabeticalByName,
  alphabeticalByArtist,
  starred,
  byYear,
  byGenre
}

String searchTypeToString(SearchType type) => type.toString().split(".")[1];

enum JukeBoxAction {
  get,
  status,
  set,
  start,
  stop,
  skip,
  add,
  clear,
  remove,
  shuffle,
  setGain,
}

String jukeBoxActionToString(JukeBoxAction action) =>
    action.toString().split(".")[1];
