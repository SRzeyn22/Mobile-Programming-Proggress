import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screen_arguments.dart';
import 'tujuan.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? title;
  String? thumbnail;
  String? shortDescription;
  String? description;

  String? genre;
  String? platform;
  String? release;
  String? cover;
  String? gameid;
  String? publisher;

  Future<void> getGame(String gameid) async {
    http.Response response = await http.get(
      Uri.parse('https://www.freetogame.com/api/game?id=$gameid'),
    );

    var results = jsonDecode(response.body);

    setState(() {
      this.gameid = gameid;
      title = results['title']?.toString();
      thumbnail = results['thumbnail']?.toString();
      shortDescription = results['short_description']?.toString();
      description = results['description']?.toString();
      genre = results['genre']?.toString();
      platform = results['platform']?.toString();
      publisher = results['publisher']?.toString();
      release = results['release_date']?.toString();
      cover = results['screenshots'][0]['image']?.toString();
    });
  }

  @override
  void initState() {
    super.initState();

    getGame('475');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0081c9),
      body: SafeArea(
        child: Center(
          child: gameid == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        margin: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Image.network(thumbnail ?? ''),

                            const SizedBox(height: 15),

                            Text(title ?? '', style: const TextStyle(fontSize: 24)),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Genre: $genre"),
                                    Text("Platform: $platform"),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Publisher: $publisher"),
                                    Text("Release: $release"),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Tujuan.routeName,
                          arguments: ScreenArguments(
                            cover ?? '',
                            title ?? '',
                            description ?? '',
                            shortDescription ?? '',
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
