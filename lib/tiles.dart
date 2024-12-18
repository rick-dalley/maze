import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const String wordsImagePath = "assets/tiles/Words.png";

class Tile {
  final String filePath;
  final String rowName;
  final String mapPath;
  late final img.Image bitmap;
  final bool hasRoom;
  final int weight;
  final int colIndex;
  Tile(
      {required this.filePath,
      required this.mapPath,
      required this.weight,
      required this.hasRoom,
      required this.rowName,
      required this.colIndex});

  // Constructor to create Tile from JSON
  factory Tile.fromJson(Map<String, dynamic> tileJson, String mapDir, String rowFolder) {
    String appPath = Directory.current.path;
    String filePath = "$appPath/assets/tiles/$mapDir/$rowFolder/tile${tileJson['index']}.png";
    final img.Image bitmap = img.decodeImage(File(filePath).readAsBytesSync())!;

    return Tile(
        filePath: filePath,
        mapPath: tileJson['path'],
        weight: tileJson['weight'] ?? 1,
        hasRoom: tileJson['room'] ?? false,
        rowName: rowFolder,
        colIndex: tileJson['index'])
      ..bitmap = bitmap;
  }
}

class TilesMap {
  Map<String, List<Tile>>? tilesByMazePath;
  late img.Image startOverlay;
  late img.Image endOverlay;
  // Constructor that initializes the map
  TilesMap();
  Map<String, List<Tile>> buildTilesMap(String mapMaze, Map<String, dynamic> jsonData) {
    Map<String, List<Tile>> tempTilesMap = {};

    List files = jsonData['files'];
    for (var file in files) {
      String mapDir = file['name'];
      if (mapDir == mapMaze) {
        List rowLabels = file['row_labels'];

        for (var rowLabel in rowLabels) {
          String rowFolder = rowLabel['name'];
          List tiles = rowLabel['tiles'];

          for (var tileJson in tiles) {
            // Create Tile using the JSON directly
            Tile newTile = Tile.fromJson(tileJson, mapDir, rowFolder);

            // Add Tile to the map
            if (!tempTilesMap.containsKey(newTile.mapPath)) {
              tempTilesMap[newTile.mapPath] = [];
            }
            tempTilesMap[newTile.mapPath]!.add(newTile);
          }
        }
      }
    }
    return tempTilesMap;
  }

  Tile? findWeightedTile(String mapPath) {
    if (tilesByMazePath == null || mapPath == " ") {
      return null;
    }
    List<Tile>? tiles = tilesByMazePath![mapPath];
    if (tiles == null || tiles.isEmpty) {
      throw Exception("No tiles found for mapPath: $mapPath");
    }

    // Weighted random selection logic
    int totalWeight = tiles.fold(0, (sum, tile) => sum + tile.weight); // Calculate total weight
    int randomValue = Random().nextInt(totalWeight); // Get a random value in the range [0, totalWeight)

    for (Tile tile in tiles) {
      if (randomValue < tile.weight) {
        return tile; // Select this tile
      }
      randomValue -= tile.weight;
    }

    // Fallback (should never happen if weights are valid)
    return tiles.first;
  }

  // Function to find a random Tile for a given mapPath
  Tile? findTile(String mapPath) {
    if (tilesByMazePath == null || mapPath == " ") {
      return null;
    }
    List<Tile>? tiles = tilesByMazePath![mapPath];
    if (tiles == null || tiles.isEmpty) {
      throw Exception("No tiles found for mapPath: $mapPath");
    }

    Random random = Random();
    int randomIndex = random.nextInt(tiles.length);
    return tiles[randomIndex];
  }

  // Function to load tiles from JSON file
  Future<void> loadTiles(String mapMaze) async {
    try {
      // String configPath = '${Directory.current.path}/assets/spec.json';
      String configPath = "${Directory.current.path}/assets/spec.json";
      String jsonContent = "";
      jsonContent = await File(configPath).readAsString();

      // Parse the JSON content
      Map<String, dynamic> jsonData = jsonDecode(jsonContent);

      // Build the tiles map
      tilesByMazePath = buildTilesMap(mapMaze, jsonData);
    } catch (e) {
      print("Error reading or parsing the JSON file: $e");
    }

    img.Image words = img.decodeImage(File(wordsImagePath).readAsBytesSync())!;
    // Extract start overlay (270x270 starting at 0,0)
    startOverlay = img.copyCrop(words, x: 0, y: 0, width: 270, height: 270);

    // Extract end overlay (270x270 starting at 270,0)
    endOverlay = img.copyCrop(words, x: 270, y: 0, width: 270, height: 270);
  }
}
