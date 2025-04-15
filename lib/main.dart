import 'dart:async' show Completer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puzzle_game/PuzzlePiece.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Puzzle',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Flutter Puzzle'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final int rows = 3;
  final int cols = 3;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  List<Widget> pieces = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> getImage(ImageSource source) async {
  final XFile? pickedFile = await _picker.pickImage(source: source);

  if (pickedFile != null) {
    final imageFile = File(pickedFile.path);
    final imageWidget = Image.file(imageFile);

    // Pre-cache image
    await precacheImage(imageWidget.image, context);

    // Now update state and split
    setState(() {
      _image = imageFile;
      pieces.clear();
    });

    splitImage(imageWidget);
  }
}


  Future<Size> getImageSize(Image image) async {
    final Completer<Size> completer = Completer<Size>();

    image.image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            completer.complete(
              Size(info.image.width.toDouble(), info.image.height.toDouble()),
            );
          }),
        );

    return completer.future;
  }

  // The main function that handles splitting the image into pieces
  void splitImage(Image image) async {
    Size imageSize = await getImageSize(image);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final List<Widget> newPieces = [];
      for (int x = 0; x < widget.rows; x++) {
        for (int y = 0; y < widget.cols; y++) {
          newPieces.add(
            PuzzlePiece(
              key: GlobalKey(),
              image: image,
              imageSize: imageSize,
              row: x,
              col: y,
              maxRow: widget.rows,
              maxCol: widget.cols,
              bringToTop: bringToTop,
              sendToBack: sendToBack,
            ),
          );
        }
      }

      setState(() {
        pieces = newPieces;
      });
    });
  }

  // Function to bring the piece to the front
  void bringToTop(Widget widget) {
    setState(() {
      pieces.remove(widget);
      pieces.add(widget);
    });
  }

  // Function to send the piece to the back
  void sendToBack(Widget widget) {
    setState(() {
      pieces.remove(widget);
      pieces.insert(0, widget);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Center(
          child:
              _image == null
                  ? const Text('No image selected.')
                  : Stack(children: pieces),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.camera),
                      title: Text('Camera'),
                      onTap: () {
                        getImage(ImageSource.camera);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.image),
                      title: Text('Gallery'),
                      onTap: () {
                        getImage(ImageSource.gallery);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        tooltip: 'New Image',
        child: Icon(Icons.add),
      ),
    );
  }
}
