import 'dart:math';

import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'favourites_manager.dart';

final FavouritesManager favouritesManager = FavouritesManager();

Future<void> toggleFavorite(String id) async {
    if (await favouritesManager.isFavourite(id)) {
      await favouritesManager.removeFavourite(id);
    } else {
      await favouritesManager.addFavourite(id);
    }
  }


void main() {
  runApp(MyApp());
  
  DatabaseHelper().database.then((db) {
    print('Database should be initialized now.');
  }).catchError((error) {
    print('Error initializing database: $error');
  });
}


class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board Game Catalog',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
  
}

class HomePage extends StatefulWidget {
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  

  final List<Widget> _pages = [
    Home(), // Home
    Search(), // Search
    Add(), // Add
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Board Game Catalog'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget{
  
  Widget build(BuildContext context){
    
    return FilteredGameListScreen();
  }
}

class Search extends StatelessWidget{
  
  Widget build(BuildContext context){
    
    return GameListScreen();
  }
}

class Add extends StatelessWidget{
  
  Widget build(BuildContext context){
    
    return GameListScreen();
  }
}

class GameListScreen extends StatelessWidget {
  const GameListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DatabaseHelper().database.then((db) {
      print('Database should be initialized');
    }).catchError((error) {
      print('Failed to initialize database: $error');
    });
    return Scaffold(
      appBar: AppBar(
        title: Text('All Board Games'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getGames(),  // Query to get all games
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No games found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var game = snapshot.data![index];
                return GameInstance(
                  gameId: game['id'].toString(),
                  gameName: game['name'],
                  minPlayers: game['min_players'],
                  maxPlayers: game['max_players'],
                  minAge: game['min_age'],
                  maxAge: game['max_age'],
                  minDuration: game['min_duration'],
                  maxDuration: game['max_duration'],
                  publisher: game['publisher_name'],
                );
              },
            );
          }
        },
      ),
    );
  }
}

// search is not working yet, maybe try with normal GameListScreen first
class FilteredGameListScreen extends StatefulWidget {
  final int minPlayersLimit;
  final int maxPlayersLimit;
  final int minAgeLimit;
  final int maxAgeLimit;
  final int minDurationLimit;
  final int maxDurationLimit;
  final String publisher;
  final bool onlyLiked;

  const FilteredGameListScreen({
    super.key,
    this.minAgeLimit = -1,
    this.maxAgeLimit = -1,
    this.minPlayersLimit = -1,
    this.maxPlayersLimit = -1,
    this.minDurationLimit = -1,
    this.maxDurationLimit = -1,
    this.publisher = 'Unspecified',
    this.onlyLiked = false,
  });

  @override
  _FilteredGameListScreenState createState() => _FilteredGameListScreenState();
}

class _FilteredGameListScreenState extends State<FilteredGameListScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allFilteredGames = [];
  List<Map<String, dynamic>> _searchFilteredGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchFilterGames);
    _loadGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    _allFilteredGames = await getFilteredGames();
    setState(() {
      _searchFilteredGames = _allFilteredGames;
      _isLoading = false;  // Loading is complete
    });
  }

  Future<List<Map<String, dynamic>>> getFilteredGames() async {
    List<Map<String, dynamic>> allGames = await DatabaseHelper().getGames();
    List<Map<String, dynamic>> allFilteredGames = [];

    for (var game in allGames) {
      bool criteriaMet = checkCriteriaSync(
        game['id'].toString(),
        game['min_age'],
        game['max_age'],
        game['min_players'],
        game['max_players'],
        game['min_duration'],
        game['max_duration'],
      );

      if (criteriaMet) {
        if (widget.onlyLiked) {
          bool isLiked = await favouritesManager.isFavourite(game['id'].toString());
          if (isLiked) {
            allFilteredGames.add(game);
          }
        } else {
          allFilteredGames.add(game);
        }
      }
    }

    return allFilteredGames;
  }

  void _searchFilterGames() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _searchFilteredGames = _allFilteredGames;
      } else {
        _searchFilteredGames = _allFilteredGames.where((game) {
          String gameName = game['name'].toString().toLowerCase();
          return gameName.contains(query);
        }).toList();
      }
    });
  }

  bool checkCriteriaSync(String gameId, int minAge, int maxAge, int minPlayers, int maxPlayers, int minDuration, int maxDuration) {
    if (widget.minAgeLimit > minAge) {
      return false;
    }
    if (widget.maxAgeLimit < maxAge) {
      return false;
    }
    if (widget.minPlayersLimit > minPlayers) {
      return false;
    }
    if (widget.maxPlayersLimit < maxPlayers) {
      return false;
    }
    if (widget.minDurationLimit > minDuration) {
      return false;
    }
    if (widget.maxDurationLimit < maxDuration) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Board Games'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search games...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (_searchFilteredGames.isEmpty
              ? Center(child: Text('No games found'))
              : ListView.builder(
                  itemCount: _searchFilteredGames.length,
                  itemBuilder: (context, index) {
                    var game = _searchFilteredGames[index];
                    return GameInstance(
                      gameId: game['id'].toString(),
                      gameName: game['name'],
                      minPlayers: game['min_players'],
                      maxPlayers: game['max_players'],
                      minAge: game['min_age'],
                      maxAge: game['max_age'],
                      minDuration: game['min_duration'],
                      maxDuration: game['max_duration'],
                      publisher: game['publisher_name'],
                    );
                  },
                )),
    );
  }
}



class GameInstance extends StatelessWidget {
  final String gameId;
  final String gameName;
  
  final int minPlayers;
  final int maxPlayers;
  final int minAge;
  final int maxAge;
  final int minDuration;
  final int maxDuration;
  final String publisher;

  const GameInstance({
    super.key,
    required this.gameId,
    required this.gameName,
    
    this.minAge = 0,
    this.maxAge = 99,
    this.minPlayers = 1,
    this.maxPlayers = 20,
    this.minDuration = 10,
    this.maxDuration = 180,
    this.publisher = 'Unspecified',
  });

  

  @override
  Widget build(BuildContext context) {
    
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameDetails(gameName: gameName),
          Row(
            children: [
              PlayerRangeWidget(minPlayers: minPlayers, maxPlayers: maxPlayers),
              SizedBox(width: 10),
              AgeRangeWidget(minAge: minAge, maxAge: maxAge),
              SizedBox(width: 10),
              LikeButton(gameId: gameId),
            ],
          ),
        ],
      ),
    );
  }
}

class GameDetails extends StatelessWidget {
  final String gameName;

  const GameDetails({super.key, required this.gameName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        gameName,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class PlayerRangeWidget extends StatelessWidget {
  final int minPlayers;
  final int maxPlayers;

  const PlayerRangeWidget({super.key, required this.minPlayers, required this.maxPlayers});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.people),
            SizedBox(width: 5),
            Text(
              '$minPlayers - $maxPlayers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class AgeRangeWidget extends StatelessWidget {
  final int minAge;
  final int maxAge;

  const AgeRangeWidget({Key? key, required this.minAge, required this.maxAge})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.child_care),
            SizedBox(width: 5),
            Text(
              '$minAge - $maxAge',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class LikeButton extends StatefulWidget {
  final String gameId;

  const LikeButton({Key? key, required this.gameId}) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  void _checkIfLiked() async {
    bool liked = await favouritesManager.isFavourite(widget.gameId);
    setState(() {
      isLiked = liked;
    });
  }

  void _toggleLike() async {
    await toggleFavorite(widget.gameId);
    setState(() {
      isLiked = !isLiked;
    });
  }
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
      color: isLiked ? Colors.red : null,
      onPressed: _toggleLike,
    );
  }
}
