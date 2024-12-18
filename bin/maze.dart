import 'package:maze/maze_generator.dart';
import 'package:maze/maze_solver.dart';

Future<void> main(List<String> arguments) async {
  // Example usage: Find a random Tile for a specific mapPath

  MazeGenerator generator = await MazeGenerator.create(25, 18, 0.9, "MappingTable2");

  Stopwatch sw = Stopwatch();
  sw.start();

  generator.generateMaze();
  // Pass start and end positions to the solver
  MazeSolver solver = MazeSolver(
    generator.grid,
    generator.startX,
    generator.startY,
    generator.endX,
    generator.endY,
  );
  // save the maze as a bitmap
  generator.saveMaze("maze.png");
  sw.stop();
  print("Elapsed:${sw.elapsedMilliseconds}");

  print("\nMaze with Solution:");
  print("Generated Maze:");
  generator.printMaze();
  solver.printSolution();
}
