import 'package:shared_preferences/shared_preferences.dart';

class AddedManager {
  static const String _addedKey = 'recently_added_games';
  int recentlyAddedLimit;

  AddedManager({
    this.recentlyAddedLimit = 5,
  });

  Future<void> saveRecentlyAdded(List<String> gameIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_addedKey, gameIds);
  }

  Future<List<String>> getRecentlyAdded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_addedKey) ?? [];
  }

  Future<void> add(String gameId) async {
    List<String> recentlyAdded = await getRecentlyAdded();
    if (!recentlyAdded.contains(gameId)) {
      recentlyAdded.add(gameId);
      if(recentlyAdded.length>recentlyAddedLimit){
        recentlyAdded.remove(recentlyAdded.first);
      }
      await saveRecentlyAdded(recentlyAdded);
    }
  }

  Future<void> removeRecentlyAdded(String gameId) async {
    List<String> recentlyAdded = await getRecentlyAdded();
    if (recentlyAdded.contains(gameId)) {
      recentlyAdded.remove(gameId);
      await saveRecentlyAdded(recentlyAdded);
    }
  }

  Future<bool> isRecentlyAdded(String gameId) async {
    List<String> recentlyAdded = await getRecentlyAdded();
    return recentlyAdded.contains(gameId);
  }
}
