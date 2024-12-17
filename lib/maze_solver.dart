import 'package:collection/collection.dart';

class Node {
  final int x, y, distance;

  Node(this.x, this.y, this.distance);
}

class MazeSolver {
  final List<List<int>> maze;
  final int rows, cols;
  final int startX, startY, endX, endY;
  final List<List<int>> directions = [
    [0, 1], // Right
    [1, 0], // Down
    [0, -1], // Left
    [-1, 0], // Up
  ];

  MazeSolver(this.maze, this.startX, this.startY, this.endX, this.endY)
      : rows = maze.length,
        cols = maze[0].length;

  /// Generates and prints the solution route using box-drawing characters.
  void printSolution() {
    List<List<int>> solutionPath = dijkstra();

    if (solutionPath.isEmpty) {
      print("No path exists.");
      return;
    }

    // Create a grid for the solution
    List<List<String>> solutionGrid = List.generate(
      rows,
      (y) => List.generate(cols, (x) => " "),
    );

    // Mark the solution path
    for (int i = 0; i < solutionPath.length - 1; i++) {
      int x = solutionPath[i][0];
      int y = solutionPath[i][1];
      int nextX = solutionPath[i + 1][0];
      int nextY = solutionPath[i + 1][1];

      // Determine the direction and mark the correct path character
      if (y == nextY) {
        solutionGrid[y][x] = "─"; // Horizontal path
      } else if (x == nextX) {
        solutionGrid[y][x] = "│"; // Vertical path
      }
    }

    // Mark corners and junctions
    for (int i = 1; i < solutionPath.length - 1; i++) {
      int x = solutionPath[i][0];
      int y = solutionPath[i][1];

      // Check neighbors to determine the correct box-drawing character
      bool up = isInPath(solutionPath, x, y - 1);
      bool down = isInPath(solutionPath, x, y + 1);
      bool left = isInPath(solutionPath, x - 1, y);
      bool right = isInPath(solutionPath, x + 1, y);

      solutionGrid[y][x] = determinePathCharacter(up, down, left, right);
    }

    // Mark start and end
    solutionGrid[startY][startX] = "S";
    solutionGrid[endY][endX] = "E";

    // Print the solution grid
    for (var row in solutionGrid) {
      print(row.join());
    }
  }

  /// Dijkstra's algorithm to find the shortest path.
  List<List<int>> dijkstra() {
    PriorityQueue<Node> pq = PriorityQueue<Node>((a, b) => a.distance.compareTo(b.distance));
    const int maxDistance = 999999;

    List<List<int>> distance = List.generate(rows, (_) => List.generate(cols, (_) => maxDistance));
    Map<String, String?> parents = {};

    pq.add(Node(startX, startY, 0));
    distance[startY][startX] = 0;
    parents["$startX,$startY"] = null;

    while (pq.isNotEmpty) {
      Node current = pq.removeFirst();
      int x = current.x;
      int y = current.y;

      if (x == endX && y == endY) {
        return _reconstructPath(parents);
      }

      for (var dir in directions) {
        int nx = x + dir[0];
        int ny = y + dir[1];

        if (isInBounds(nx, ny) && maze[ny][nx] == 0) {
          int newDistance = current.distance + 1;

          if (newDistance < distance[ny][nx]) {
            distance[ny][nx] = newDistance;
            pq.add(Node(nx, ny, newDistance));
            parents["$nx,$ny"] = "$x,$y";
          }
        }
      }
    }

    return [];
  }

  /// Reconstructs the path from end to start.
  List<List<int>> _reconstructPath(Map<String, String?> parents) {
    List<List<int>> path = [];
    String? current = "$endX,$endY";

    while (current != null) {
      List<String> coords = current.split(",");
      path.add([int.parse(coords[0]), int.parse(coords[1])]);
      current = parents[current];
    }

    return path.reversed.toList();
  }

  /// Helper: Checks if a cell is part of the solution path.
  bool isInPath(List<List<int>> path, int x, int y) {
    return path.any((point) => point[0] == x && point[1] == y);
  }

  /// Determines the box-drawing character for a path cell.
  String determinePathCharacter(bool up, bool down, bool left, bool right) {
    if (up && down && left && right) return "┼"; // Crossing
    if (up && down && left) return "┤"; // Left T-junction
    if (up && down && right) return "├"; // Right T-junction
    if (left && right && up) return "┴"; // Bottom T-junction
    if (left && right && down) return "┬"; // Top T-junction
    if (up && down) return "│"; // Vertical path
    if (left && right) return "─"; // Horizontal path
    if (up && right) return "└"; // Bottom-left corner
    if (up && left) return "┘"; // Bottom-right corner
    if (down && right) return "┌"; // Top-left corner
    if (down && left) return "┐"; // Top-right corner
    return " "; // Blank
  }

  /// Checks if a given cell is within bounds.
  bool isInBounds(int x, int y) {
    return x >= 0 && y >= 0 && x < cols && y < rows;
  }
}
