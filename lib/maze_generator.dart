import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:maze/tiles.dart';

// Pair = stores the result of a function that needs to return two values as a tuple
class Pair<T> {
  final T x;
  final T y;

  Pair(this.x, this.y);

  // Override == operator to compare Pair objects
  @override
  bool operator ==(Object other) => identical(this, other) || (other is Pair<T> && other.x == x && other.y == y);

  // Override hashCode to ensure correct behavior in collections
  @override
  int get hashCode => Object.hash(x, y); // Use Object.hash for better combination
}

class MazeGenerator {
  final int width;
  final int height;
  final double complexity; // Value between 0.0 and 1.0
  final Random random = Random();
  static const int tileSize = 270; // Assuming tiles are 270x270 pixels

  // Grid where 1 = wall, 0 = path
  late List<List<int>> grid;

  // Start and end points
  late int startX = 0, startY = 0;
  late int endX = 0, endY = 0;
  TilesMap tilesMap = TilesMap();
  late img.Image background;

  MazeGenerator(this.width, this.height, this.complexity)
      : assert(complexity >= 0.0 && complexity <= 1.0, "Complexity must be between 0.0 and 1.0") {
    // Initialize the grid with walls
    grid = List.generate(height, (_) => List.filled(width, 1));
  }

  MazeGenerator._internal(this.width, this.height, this.complexity, this.tilesMap)
      : assert(complexity >= 0.0 && complexity <= 1.0, "Complexity must be between 0.0 and 1.0") {
    grid = List.generate(height, (_) => List.filled(width, 1));
  }

// Factory constructor to initialize tiles, overlays, and the canvas
  static Future<MazeGenerator> create(int width, int height, double complexity, String mapTilesSource) async {
    TilesMap tilesMap = TilesMap();
    await tilesMap.loadTiles(mapTilesSource);

    MazeGenerator generator = MazeGenerator._internal(width, height, complexity, tilesMap);

    // Pre-create a white canvas
    generator.background = img.Image(width: width * tileSize, height: height * tileSize);
    img.fill(generator.background, color: img.ColorUint8.rgb(255, 255, 255)); // White background

    return generator;
  }

  Future<void> generateMaze() async {
    List<List<int>> directions = [
      [0, -2], // Up
      [0, 2], // Down
      [-2, 0], // Left
      [2, 0], // Right
    ];

    // Pick random starting point
    startX = random.nextInt(width ~/ 2) * 2;
    startY = random.nextInt(height ~/ 2) * 2;
    grid[startY][startX] = 0;

    // Pick a random ending point far from the start
    do {
      endX = random.nextInt(width ~/ 2) * 2;
      endY = random.nextInt(height ~/ 2) * 2;
    } while (
        (startX == endX && startY == endY) || manhattanDistance(startX, startY, endX, endY) < (width + height) ~/ 4);

    grid[endY][endX] = 0; // Ensure the end is also a path

    List<List<int>> frontier = [];
    addFrontiers(startX, startY, directions, frontier);

    while (frontier.isNotEmpty) {
      int index = random.nextInt(frontier.length);
      List<int> cell = frontier.removeAt(index);
      int x = cell[0];
      int y = cell[1];

      // Use complexity to skip carving some paths
      if (random.nextDouble() > complexity) continue;

      List<List<int>> neighbors = [];
      for (var dir in directions) {
        int nx = x + dir[0];
        int ny = y + dir[1];
        if (isInBounds(nx, ny) && grid[ny][nx] == 0) {
          neighbors.add([nx, ny]);
        }
      }

      if (neighbors.isNotEmpty) {
        List<int> neighbor = neighbors[random.nextInt(neighbors.length)];
        int midX = (x + neighbor[0]) ~/ 2;
        int midY = (y + neighbor[1]) ~/ 2;

        grid[midY][midX] = 0; // Carve the wall between
        grid[y][x] = 0; // Mark the current cell as part of the maze
      }

      addFrontiers(x, y, directions, frontier);
    }
  }

  void addFrontiers(int x, int y, List<List<int>> directions, List<List<int>> frontier) {
    for (var dir in directions) {
      int nx = x + dir[0];
      int ny = y + dir[1];
      if (isInBounds(nx, ny) && grid[ny][nx] == 1) {
        frontier.add([nx, ny]);
      }
    }
  }

  bool isInBounds(int x, int y) {
    return x >= 0 && y >= 0 && x < width && y < height;
  }

  int manhattanDistance(int x1, int y1, int x2, int y2) {
    return (x1 - x2).abs() + (y1 - y2).abs();
  }

  void printMaze() {
    for (int y = 0; y < height; y++) {
      String row = "";
      for (int x = 0; x < width; x++) {
        if (x == startX && y == startY) {
          row += "S"; // Start point
        } else if (x == endX && y == endY) {
          row += "E"; // End point
        } else {
          row += determinePathCharacter(x, y);
        }
      }
      print(row);
    }
  }

  Future<void> saveMaze(String targetLocation) async {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (grid[y][x] == 1) continue; // Skip walls
        // Determine the tile for this position
        // String characterPath = determinePathCharacter(x, y);
        // Tile? tile = tilesMap.findTile(characterPath);
        Tile? tile = determineTile(x, y);
        if (tile != null) {
          int posX = x * tileSize;
          int posY = y * tileSize;

          // Place the tile on the canvas
          img.compositeImage(background, tile.bitmap, dstX: posX, dstY: posY);

          // Overlay "Start" or "End" text if applicable
          if (x == startX && y == startY) {
            // Overlay startOverlay onto outputImage
            img.compositeImage(
              background, // The base image
              tilesMap.startOverlay, // The overlay image
              dstX: posX, // X position for the overlay
              dstY: posY, // Y position for the overlay
            );
          } else if (x == endX && y == endY) {
            // Overlay startOverlay onto outputImage
            img.compositeImage(
              background, // The base image
              tilesMap.endOverlay, // The overlay image
              dstX: posX, // X position for the overlay
              dstY: posY, // Y position for the overlay
            );
          }
        }
      }
    }

    // Save the final stitched image
    File outputFile = File(targetLocation);
    outputFile.writeAsBytesSync(img.encodePng(background));
    print("Maze saved to $targetLocation");
  }

  Tile? determineTile(int x, int y) {
    // Check neighbors to determine the type of path character
    bool up = isInBounds(x, y - 1) && grid[y - 1][x] == 0;
    bool down = isInBounds(x, y + 1) && grid[y + 1][x] == 0;
    bool left = isInBounds(x - 1, y) && grid[y][x - 1] == 0;
    bool right = isInBounds(x + 1, y) && grid[y][x + 1] == 0;

    // Dead end logic: If only one neighbor is valid
    int neighbors = (up ? 1 : 0) + (down ? 1 : 0) + (left ? 1 : 0) + (right ? 1 : 0);
    if (neighbors == 1) {
      if (up) return tilesMap.findTile("↓"); // Dead end pointing down
      if (down) return tilesMap.findTile("↑"); // Dead end pointing up
      if (left) return tilesMap.findTile("→"); // Dead end pointing right
      if (right) return tilesMap.findTile("←"); // Dead end pointing left
    }

    // Existing logic for other tile types
    String pathCharacter;

    if (up && down && left && right) {
      pathCharacter = "┼"; // Crossing paths
    } else if (up && down && left) {
      pathCharacter = "┤"; // T-junction (left open)
    } else if (up && down && right) {
      pathCharacter = "├"; // T-junction (right open)
    } else if (left && right && up) {
      pathCharacter = "┴"; // T-junction (bottom open)
    } else if (left && right && down) {
      pathCharacter = "┬"; // T-junction (top open)
    } else if (up && down) {
      pathCharacter = "│"; // Vertical path
    } else if (left && right) {
      pathCharacter = "─"; // Horizontal path
    } else if (up && right) {
      pathCharacter = "└"; // Bottom-left corner
    } else if (up && left) {
      pathCharacter = "┘"; // Bottom-right corner
    } else if (down && right) {
      pathCharacter = "┌"; // Top-left corner
    } else if (down && left) {
      pathCharacter = "┐"; // Top-right corner
    } else {
      throw Exception("No valid Tile found at ($x, $y)!");
    }

    // Return the full Tile object using TilesMap
    return tilesMap.findTile(pathCharacter);
  }

  // Example method: Determines the path character (you already have this)
  String determinePathCharacter(int x, int y) {
    // Example logic based on neighbors
    bool up = isInBounds(x, y - 1) && grid[y - 1][x] == 0;
    bool down = isInBounds(x, y + 1) && grid[y + 1][x] == 0;
    bool left = isInBounds(x - 1, y) && grid[y][x - 1] == 0;
    bool right = isInBounds(x + 1, y) && grid[y][x + 1] == 0;

    if (grid[y][x] == 1) return " "; // Non-walkable space

    if (up && down && left && right) return "┼"; // Crossing paths
    if (up && down && left) return "┤"; // T-junction (left open)
    if (up && down && right) return "├"; // T-junction (right open)
    if (left && right && up) return "┴"; // T-junction (bottom open)
    if (left && right && down) return "┬"; // T-junction (top open)
    if (up && down) return "│"; // Vertical path
    if (left && right) return "─"; // Horizontal path
    if (up && right) return "└"; // Bottom-left corner
    if (up && left) return "┘"; // Bottom-right corner
    if (down && right) return "┌"; // Top-left corner
    if (down && left) return "┐"; // Top-right corner
    return " "; // Default (shouldn't happen)
  }

  // Example helper: Check bounds (you already have this)
}
