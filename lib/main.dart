import 'dart:math';

import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'favourites_manager.dart';
import 'added_manager.dart';

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
        title: Text('Game Gallery'),
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
            icon: Icon(Icons.my_library_books_rounded),
            label: 'Library',
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
    
    return FilteredGameListScreen(onlyLiked: true, title: 'My Games',);
  }
}

class Search extends StatelessWidget{
  
  Widget build(BuildContext context){
    
    return FilteredGameListScreen(onlyLiked: false);
  }
}

class Add extends StatefulWidget {
  @override
  State<Add> createState() => _AddState();
}

class _AddState extends State<Add> {
  
  final GlobalKey<RecentlyAddedGameListScreenState> _recentlyAddedKey = GlobalKey<RecentlyAddedGameListScreenState>();

  void _refreshRecentlyAddedGames() {
    _recentlyAddedKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Game'),
      ),
      body: Column(
        children: [
          AddGameInstance(onGameAdded: _refreshRecentlyAddedGames),   // The form for adding a new game
          Expanded(
            child: RecentlyAddedGameListScreen(
              key: _recentlyAddedKey,  // Assign the key to the RecentlyAddedGameListScreen
              numGames: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// basic GameListScreen, use this to build specific ones

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

class RecentlyAddedGameListScreen extends StatefulWidget {
  
  final int numGames;
  const RecentlyAddedGameListScreen({super.key, this.numGames = 5});

  @override
  RecentlyAddedGameListScreenState createState() => RecentlyAddedGameListScreenState();
}

class RecentlyAddedGameListScreenState extends State<RecentlyAddedGameListScreen> {
  
  late AddedManager recentlyAddedManager;

  @override
  void initState() {
    super.initState();
    recentlyAddedManager = AddedManager(recentlyAddedLimit: widget.numGames);
  }


  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DatabaseHelper().database.then((db) {
      print('Database should be initialized');
    }).catchError((error) {
      print('Failed to initialize database: $error');
    });
    return Scaffold(
      appBar: AppBar(
        title: Text('Recently Added Games'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _getRecentlyAddedGames(), 
      builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No recently added games'));
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
                  publisher: 'unspecified',
                );
              },
            );
          }
        },
      ),
    );
  }
  Future<List<Map<String, dynamic>>> _getRecentlyAddedGames() async {
  // Fetch all games first
    List<Map<String, dynamic>> allGames = await DatabaseHelper().getGames();

  // Filter the games asynchronously
    List<Map<String, dynamic>> recentlyAddedGames = [];
    for (var game in allGames) {
      if (await recentlyAddedManager.isRecentlyAdded(game['id'].toString())) {
       recentlyAddedGames.add(game);
     }
    }
    return recentlyAddedGames;
  }
}

// search is not working yet, maybe try with normal GameListScreen first
class FilteredGameListScreen extends StatefulWidget {
   int minPlayersLimit;
   int maxPlayersLimit;
   int minAgeLimit;
   int maxAgeLimit;
   int minDurationLimit;
   int maxDurationLimit;
   String publisher;
   bool onlyLiked;
   String title;


  FilteredGameListScreen({
    super.key,
    this.minAgeLimit = -1,
    this.maxAgeLimit = -1,
    this.minPlayersLimit = -1,
    this.maxPlayersLimit = -1,
    this.minDurationLimit = -1,
    this.maxDurationLimit = -1,
    this.publisher = 'Unspecified',
    this.onlyLiked = false,
    this.title = 'All Games'
  });

  @override
  _FilteredGameListScreenState createState() => _FilteredGameListScreenState();
}

class _FilteredGameListScreenState extends State<FilteredGameListScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allFilteredGames = [];
  List<Map<String, dynamic>> _searchFilteredGames = [];
  bool _isLoading = true;
  bool _showFilters = false;

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
  bool ageCriteria = (widget.minAgeLimit == -1 || (minAge != -1 && widget.minAgeLimit <= minAge)) &&
                     (widget.maxAgeLimit == -1 || (maxAge != -1 && widget.maxAgeLimit >= maxAge));

  bool playersCriteria = (widget.minPlayersLimit == -1 || (minPlayers != -1 && widget.minPlayersLimit <= minPlayers)) &&
                         (widget.maxPlayersLimit == -1 || (maxPlayers != -1 && widget.maxPlayersLimit >= maxPlayers));

  bool durationCriteria = (widget.minDurationLimit == -1 || (minDuration != -1 && widget.minDurationLimit <= minDuration)) &&
                          (widget.maxDurationLimit == -1 || (maxDuration != -1 && widget.maxDurationLimit >= maxDuration));

  return ageCriteria && playersCriteria && durationCriteria;
}

void _filterGames() {
  setState(() {
    _searchFilterGames();  // Reapply the search filter

    _searchFilteredGames = _allFilteredGames.where((game) {
      bool matchesPlayers = (widget.minPlayersLimit == -1 || game['min_players'] >= widget.minPlayersLimit) &&
                            (widget.maxPlayersLimit == -1 || game['max_players'] <= widget.maxPlayersLimit);

      bool matchesAge = (widget.minAgeLimit == -1 || game['min_age'] >= widget.minAgeLimit) &&
                        (widget.maxAgeLimit == -1 || game['max_age'] <= widget.maxAgeLimit);

      bool matchesDuration = (widget.minDurationLimit == -1 || game['min_duration'] >= widget.minDurationLimit) &&
                             (widget.maxDurationLimit == -1 || game['max_duration'] <= widget.maxDurationLimit);

      return matchesPlayers && matchesAge && matchesDuration;
    }).toList();
  });
}



  @override
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
          
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showFilters ? 220.0 : 100.0),  // Adjust based on whether filters are shown
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
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
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters'),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        child: Row(
                          children: [
                            Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
                            Icon(_showFilters ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Min Players',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    widget.minPlayersLimit = int.tryParse(value) ?? -1;
                                  });
                                  _filterGames();
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Max Players',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    widget.maxPlayersLimit = int.tryParse(value) ?? -1;
                                  });
                                  _filterGames();
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Min Age',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    widget.minAgeLimit = int.tryParse(value) ?? -1;
                                  });
                                  _filterGames();
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Max Age',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    widget.maxAgeLimit = int.tryParse(value) ?? -1;
                                  });
                                  _filterGames();
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Min Duration (mins)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    widget.minDurationLimit = int.tryParse(value) ?? -1;
                                  });
                                  _filterGames();
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Max Duration (mins)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    widget.maxDurationLimit = int.tryParse(value) ?? -1;
                                  });
                                  _filterGames();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (_searchFilteredGames.isEmpty
              ? Center(child: Text('No games found'))
              : Expanded(
                child: ListView.builder(
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
                        publisher: 'unspecified',
                      );
                    },
                  ),
              )),
    );
  }

}



class GameInstance extends StatefulWidget {
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
  State<GameInstance> createState() => _GameInstanceState();
}

class _GameInstanceState extends State<GameInstance> {
  bool _isDeleted = false;

  void _addGameToDatabase() async {

    // Prepare the game data to be inserted into the database
    Map<String, dynamic> newGame = {
      'name': widget.gameName,
      'min_players': widget.minPlayers,
      'max_players': widget.maxPlayers,
      'min_age': widget.minAge,
      'max_age': widget.maxAge,
      'min_duration': widget.minDuration,
      'max_duration': widget.maxDuration
    };

    // Insert the game into the database, add it to recently added games make it a favourite by default
    DatabaseHelper dbHelper = DatabaseHelper();
    int newGameId = await dbHelper.insertGame(newGame);
    print('game should be back in databese');
    
    AddedManager recentlyAdded = AddedManager();
    recentlyAdded.add(newGameId.toString());
    
    FavouritesManager favs = FavouritesManager();
    favs.addFavourite(newGameId.toString());

    //rebuild widget
    setState(() { _isDeleted = false; });
  }
  
  void _removeGameFromDatabase() async {
    // Remove the game from the database,recently added games and favourites
    DatabaseHelper dbHelper = DatabaseHelper();
    dbHelper.deleteGame(int.parse(widget.gameId));
    
    AddedManager recentlyAdded = AddedManager();
    recentlyAdded.removeRecentlyAdded(widget.gameId);
 
    FavouritesManager favs = FavouritesManager();
    favs.removeFavourite(widget.gameId);

    //rebuild widget here
    setState(() { _isDeleted = true; });

  }

  @override
  Widget build(BuildContext context) {
    
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GameDetails(gameName: widget.gameName),
              Spacer(),
              _isDeleted ? IconButton(onPressed: _addGameToDatabase, icon: Icon(Icons.add)) : IconButton(onPressed: _removeGameFromDatabase, icon: Icon(Icons.delete)),
              SizedBox(width: 10),
              LikeButton(gameId: widget.gameId)
            ],
          ),
          Row(
            children: [
              PlayerRangeWidget(minPlayers: widget.minPlayers, maxPlayers: widget.maxPlayers),
              SizedBox(width: 10),
              AgeRangeWidget(minAge: widget.minAge, maxAge: widget.maxAge),
              SizedBox(width: 10),
              DurationWidget(minDuration: widget.minDuration, maxDuration: widget.maxDuration),
              
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

  const AgeRangeWidget({super.key, required this.minAge, required this.maxAge});

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
class DurationWidget extends StatelessWidget {
  final int minDuration;
  final int maxDuration;

  const DurationWidget({super.key, required this.minDuration, required this.maxDuration});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.timer_outlined),
            SizedBox(width: 5),
            Text(
              '$minDuration - $maxDuration',
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

  const LikeButton({super.key, required this.gameId});

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

class AddGameInstance extends StatefulWidget {
  final VoidCallback onGameAdded;

  const AddGameInstance({super.key, required this.onGameAdded});

  @override
  _AddGameInstanceState createState() => _AddGameInstanceState();
}

class _AddGameInstanceState extends State<AddGameInstance> {
  // Controllers for each input field
  final TextEditingController _gameNameController = TextEditingController();
  final TextEditingController _minPlayersController = TextEditingController();
  final TextEditingController _maxPlayersController = TextEditingController();
  final TextEditingController _minAgeController = TextEditingController();
  final TextEditingController _maxAgeController = TextEditingController();
  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _gameNameController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _minDurationController.dispose();
    _maxDurationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _gameNameController.clear();
    _minPlayersController.clear();
    _maxPlayersController.clear();
    _minAgeController.clear();
    _maxAgeController.clear();
    _minDurationController.clear();
   _maxDurationController.clear();

    // Trigger a rebuild of the widget
    setState(() {});

  }

  void _addGameToDatabase() async {
    String gameName = _gameNameController.text.trim();

    if (gameName.isEmpty) {
      // Show a simple alert if the game name is not provided
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please provide a game name.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Prepare the game data to be inserted into the database
    Map<String, dynamic> newGame = {
      'name': gameName,
      'min_players': int.tryParse(_minPlayersController.text) ?? 0,
      'max_players': int.tryParse(_maxPlayersController.text) ?? 99,
      'min_age': int.tryParse(_minAgeController.text) ?? 0,
      'max_age': int.tryParse(_maxAgeController.text) ?? 99,
      'min_duration': int.tryParse(_minDurationController.text) ?? 0,
      'max_duration': int.tryParse(_maxDurationController.text) ?? 300,
    };

    // Insert the game into the database, add it to recently added games and make it a favourite by default
    DatabaseHelper dbHelper = DatabaseHelper();
    int newGameId = await dbHelper.insertGame(newGame);
    
    AddedManager recentlyAdded = AddedManager();
    recentlyAdded.add(newGameId.toString());

    FavouritesManager favs = FavouritesManager();
    favs.addFavourite(newGameId.toString());

    // Reset the form by creating a new AddGameInstance
    _resetForm();
    // Notify the parent to refresh the recently added games list
    widget.onGameAdded();

  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: GameDetailsInput(controller: _gameNameController)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addGameToDatabase,
                ),
              ],
            ),
            Row(
              children: [
                PlayerRangeInput(
                  minController: _minPlayersController,
                  maxController: _maxPlayersController,
                ),
                SizedBox(width: 10),
                AgeRangeInput(
                  minController: _minAgeController,
                  maxController: _maxAgeController,
                ),
                SizedBox(width: 10),
                DurationInput(
                  minController: _minDurationController,
                  maxController: _maxDurationController,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class GameDetailsInput extends StatelessWidget {
  final TextEditingController controller;

  const GameDetailsInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Game Name',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class PlayerRangeInput extends StatelessWidget {
  final TextEditingController minController;
  final TextEditingController maxController;

  const PlayerRangeInput({super.key, required this.minController, required this.maxController});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 5),
                  Text('Players'),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    '-',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),                  
                  SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AgeRangeInput extends StatelessWidget {
  final TextEditingController minController;
  final TextEditingController maxController;

  const AgeRangeInput({super.key, required this.minController, required this.maxController});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.child_care),
                  SizedBox(width: 5),
                  Text('Age'),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    '-',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),                  
                  SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DurationInput extends StatelessWidget {
  final TextEditingController minController;
  final TextEditingController maxController;

  const DurationInput({super.key, required this.minController, required this.maxController});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined),
                  SizedBox(width: 5),
                  Text('Duration'),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    '-',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
