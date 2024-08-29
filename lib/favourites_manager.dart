import 'package:shared_preferences/shared_preferences.dart';

class FavouritesManager {
  static const String _favouritesKey = 'favourite_games';

  Future<void> saveFavourites(List<String> gameIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favouritesKey, gameIds);
  }

  Future<List<String>> getFavourites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favouritesKey) ?? [];
  }

  Future<void> addFavourite(String gameId) async {
    List<String> favourites = await getFavourites();
    if (!favourites.contains(gameId)) {
      favourites.add(gameId);
      await saveFavourites(favourites);
    }
  }

  Future<void> removeFavourite(String gameId) async {
    List<String> favourites = await getFavourites();
    if (favourites.contains(gameId)) {
      favourites.remove(gameId);
      await saveFavourites(favourites);
    }
  }

  Future<bool> isFavourite(String gameId) async {
    List<String> favourites = await getFavourites();
    return favourites.contains(gameId);
  }
}
