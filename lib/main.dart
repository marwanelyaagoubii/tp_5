import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'OMDb API Demo',
      home: MovieListScreen(),
    );
  }
}

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _movies = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OMDb Movie Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search Movies'),
              onSubmitted: (value) {
                _searchMovies(value);
              },
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _movies.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_movies[index].title),
                    subtitle: Text(_movies[index].year),
                    leading: _movies[index].poster != 'N/A'
                        ? Image.network(_movies[index].poster, width: 50)
                        : const Icon(Icons.movie),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailScreen(movie: _movies[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchMovies(String query) async {
    const apiKey = '48f9aeb4';
    final apiUrl = 'http://www.omdbapi.com/?apikey=$apiKey&s=$query';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['Response'] == 'True') {
        final List<dynamic> movies = data['Search'];

        setState(() {
          _movies = movies.map((movie) => Movie.fromJson(movie)).toList();
        });
      } else {
        setState(() {
          _movies = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['Error'] ?? 'No movies found.')),
        );
      }
    } else {
      throw Exception('Failed to load movies');
    }
  }
}

class Movie {
  final String title;
  final String year;
  final String poster;
  final String imdbID;

  Movie({required this.title, required this.year, required this.poster, required this.imdbID});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['Title'],
      year: json['Year'],
      poster: json['Poster'],
      imdbID: json['imdbID'],
    );
  }
}

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Map<String, dynamic>? _movieDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _MovieDetails();
  }

  Future<void> _MovieDetails() async {
    const apiKey = '48f9aeb4';
    final apiUrl = 'http://www.omdbapi.com/?apikey=$apiKey&i=${widget.movie.imdbID}';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        _movieDetails = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _movieDetails != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_movieDetails!['Poster'] != 'N/A')
                          Center(
                            child: Image.network(
                              _movieDetails!['Poster'],
                              height: 300,
                            ),
                          ),
                        const SizedBox(height: 16.0),
                        Text(
                          _movieDetails!['Title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text('Year: ${_movieDetails!['Year']}'),
                        Text('Genre: ${_movieDetails!['Genre']}'),
                        Text('Director: ${_movieDetails!['Director']}'),
                        const SizedBox(height: 16.0),
                        Text(
                          _movieDetails!['Plot'],
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ],
                    )
                  : const Center(child: Text('Movie details not available.')),
            ),
    );
  }
}
