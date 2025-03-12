import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(CatAndMouseGame());
}

class CatAndMouseGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat and Mouse Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CharacterSelectionScreen(),
    );
  }
}

class CharacterSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select character')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GameScreen(isCatPlayer: true)),
              ),
              child: Text('🐱 Play as Cat'), // '🐱' : i == mousePosition ? '🐭' 
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GameScreen(isCatPlayer: false)),
              ),
              child: Text('🐭 Play as Mouse'),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final bool isCatPlayer;
  GameScreen({required this.isCatPlayer});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int pointCount = 5;
  static const double radius = 150;
  late List<Offset> points;
  int catPosition = 0;
  int mousePosition = 2;
  int moveCount = 0;
  bool isCatTurn = true;
  double randomAngle = Random().nextInt(100).toDouble();
  final Map<int, List<int>> connections = {
    0: [1, 4],
    1: [0, 2, 5],
    2: [1, 3],
    3: [2, 4, 5],
    4: [0, 3, 5],
    5: [1, 3, 4],
  };

  @override
  void initState() {
    super.initState();
    _generatePoints();
    if (!widget.isCatPlayer) autoMove();
  }

  void _generatePoints() {
    points = List.generate(pointCount, (i) {
      double angle = (2 * pi * i ) / pointCount + randomAngle;
      return Offset(cos(angle) * radius + radius, sin(angle) * radius + radius);
    })..add(Offset(radius, radius));
  }

  void moveCharacter(int selectedPosition) {
    if (!connections[currentPosition()]!.contains(selectedPosition)) return;

    setState(() {
      if (isCatTurn) catPosition = selectedPosition;
      else mousePosition = selectedPosition;

      if (catPosition == mousePosition) {
        _showGameOverDialog('The mouse is caught!');
      } else {
        isCatTurn = !isCatTurn;
        if (!isCurrentPlayer()){
          autoMove();
        } 
        else{
          moveCount++;
        }
      }
    });
  }

  void autoMove() {
    Future.delayed(Duration(milliseconds: 600), () {
      if (isCatTurn && !widget.isCatPlayer) {
        moveCharacter(bestMove(catPosition, mousePosition, aggressive: true));
      } else if (!isCatTurn && widget.isCatPlayer) {
        moveCharacter(bestMove(mousePosition, catPosition, aggressive: false));
      }
    });
  }


int bestMove(int current, int opponent, {required bool aggressive}) {
  List<int> options = connections[current]!;
  options.shuffle();

  if (aggressive) {
    options.sort((a, b) {
      double distA = distance(points[a], points[opponent]);
      double distB = distance(points[b], points[opponent]);

      // Если можно двигаться прямо к мыши - сделать это
      if (connections[current]!.contains(opponent)) {
        return a == opponent ? -1 : b == opponent ? 1 : 0;
      }

      // Иначе, попытаться загнать мышь в треугольник или приблизиться к ней
      if ([0, 3, 4].contains(opponent) && [0, 3, 4].contains(a)) return -1;
      if ([0, 3, 4].contains(opponent) && [0, 3, 4].contains(b)) return 1;

      return distA.compareTo(distB);
    });
  } else {
    options.sort((a, b) {
      double distA = distance(points[a], points[opponent]);
      double distB = distance(points[b], points[opponent]);

      // Мышь избегает точек, где её могут поймать
      if (connections[opponent]!.contains(a)) return 1;
      if (connections[opponent]!.contains(b)) return -1;

      return distB.compareTo(distA);
    });
  }

  return options.first;
}


  double distance(Offset a, Offset b) => (a - b).distance;

  bool isCurrentPlayer() => (isCatTurn && widget.isCatPlayer) || (!isCatTurn && !widget.isCatPlayer);

  int currentPosition() => isCatTurn ? catPosition : mousePosition;

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cat and Mouse Game'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text('Restart'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cat and Mouse Game')),
      body: Center(

        child: 
        
        Column(
          children: [
            Text('Move Count: $moveCount',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            GestureDetector(
              onTapUp: (details) {
                RenderBox box = context.findRenderObject() as RenderBox;
                Offset localPosition = box.globalToLocal(details.localPosition);
            
                for (int i = 0; i < points.length; i++) {
                  if ((points[i] - localPosition).distance <= 30 && isCurrentPlayer()) {
                    moveCharacter(i);
                    break;
                  }
                }
              },
              child: CustomPaint(
                size: Size(2 * radius, 2 * radius),
                painter: GamePainter(points, catPosition, mousePosition),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class GamePainter extends CustomPainter {
  final List<Offset> points;
  final int catPosition;
  final int mousePosition;
  

  GamePainter(this.points, this.catPosition, this.mousePosition);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.black..strokeWidth = 3;
    for (int i = 0; i < points.length - 1; i++) {
      if (i != 0 && i != 2) {
        canvas.drawLine(points[i], points.last, paint);
      }
      canvas.drawLine(points[i], points[(i + 1) % (points.length - 1)], paint);
    }

    for (int i = 0; i < points.length; i++) {
      TextSpan span = TextSpan(
          text: i == catPosition ? '🐱' : i == mousePosition ? '🐭' : '',
          style: TextStyle(fontSize: 30));
      TextPainter tp = TextPainter(
          text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, points[i] - Offset(15, 15));
    }
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
