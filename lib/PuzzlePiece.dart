import 'dart:math';
import 'package:flutter/material.dart';

class PuzzlePiece extends StatefulWidget {
  final Image image;
  final Size imageSize;
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;
  final Function(PuzzlePiece)? bringToTop;
  final Function(PuzzlePiece)? sendToBack;

  const PuzzlePiece({
    Key? key,
    required this.image,
    required this.imageSize,
    required this.row,
    required this.col,
    required this.maxRow,
    required this.maxCol,
    this.bringToTop,
    this.sendToBack,
  }) : super(key: key);

  @override
  PuzzlePieceState createState() => PuzzlePieceState();
}

class PuzzlePieceState extends State<PuzzlePiece> {
  double? top;
  double? left;
  bool isMovable = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imageWidth = screenSize.width;
    final imageHeight =
        screenSize.width * widget.imageSize.height / widget.imageSize.width;

    final pieceWidth = imageWidth / widget.maxCol;
    final pieceHeight = imageHeight / widget.maxRow;

    top ??= max(0, Random().nextDouble() * (imageHeight - pieceHeight)) - widget.row * pieceHeight;
    left ??= max(0, Random().nextDouble() * (imageWidth - pieceWidth)) - widget.col * pieceWidth;

    return Positioned(
      top: top,
      left: left,
      width: imageWidth,
      child: GestureDetector(
        onTap: () {
          if (isMovable) {
            widget.bringToTop?.call(widget);
          }
        },
        onPanStart: (_) {
          if (isMovable) {
            widget.bringToTop?.call(widget);
          }
        },
        onPanUpdate: (dragUpdateDetails) {
          if (!isMovable) return;

          setState(() {
            top = (top ?? 0) + dragUpdateDetails.delta.dy;
            left = (left ?? 0) + dragUpdateDetails.delta.dx;

            // Check snap to original spot
            if (-10 < top! && top! < 10 && -10 < left! && left! < 10) {
              top = 0;
              left = 0;
              isMovable = false;
              widget.sendToBack?.call(widget);
            }
          });
        },
        child: ClipPath(
          clipper: PuzzlePieceClipper(
            widget.row,
            widget.col,
            widget.maxRow,
            widget.maxCol,
          ),
          child: CustomPaint(
            foregroundPainter: PuzzlePiecePainter(
              widget.row,
              widget.col,
              widget.maxRow,
              widget.maxCol,
            ),
            child: SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: widget.image,
            ),
          ),
        ),
      ),
    );
  }
}

// ----- Clipper -----

class PuzzlePieceClipper extends CustomClipper<Path> {
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  PuzzlePieceClipper(this.row, this.col, this.maxRow, this.maxCol);

  @override
  Path getClip(Size size) {
    return getPiecePath(size, row, col, maxRow, maxCol);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ----- Painter -----

class PuzzlePiecePainter extends CustomPainter {
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  PuzzlePiecePainter(this.row, this.col, this.maxRow, this.maxCol);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(getPiecePath(size, row, col, maxRow, maxCol), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ----- Path Generator -----

Path getPiecePath(Size size, int row, int col, int maxRow, int maxCol) {
  final width = size.width / maxCol;
  final height = size.height / maxRow;
  final offsetX = col * width;
  final offsetY = row * height;
  final bumpSize = height / 4;

  final path = Path();
  path.moveTo(offsetX, offsetY);

  // Top side
  if (row == 0) {
    path.lineTo(offsetX + width, offsetY);
  } else {
    path.lineTo(offsetX + width / 3, offsetY);
    path.cubicTo(
      offsetX + width / 6, offsetY - bumpSize,
      offsetX + width / 6 * 5, offsetY - bumpSize,
      offsetX + width / 3 * 2, offsetY,
    );
    path.lineTo(offsetX + width, offsetY);
  }

  // Right side
  if (col == maxCol - 1) {
    path.lineTo(offsetX + width, offsetY + height);
  } else {
    path.lineTo(offsetX + width, offsetY + height / 3);
    path.cubicTo(
      offsetX + width - bumpSize, offsetY + height / 6,
      offsetX + width - bumpSize, offsetY + height / 6 * 5,
      offsetX + width, offsetY + height / 3 * 2,
    );
    path.lineTo(offsetX + width, offsetY + height);
  }

  // Bottom side
  if (row == maxRow - 1) {
    path.lineTo(offsetX, offsetY + height);
  } else {
    path.lineTo(offsetX + width / 3 * 2, offsetY + height);
    path.cubicTo(
      offsetX + width / 6 * 5, offsetY + height - bumpSize,
      offsetX + width / 6, offsetY + height - bumpSize,
      offsetX + width / 3, offsetY + height,
    );
    path.lineTo(offsetX, offsetY + height);
  }

  // Left side
  if (col == 0) {
    path.close();
  } else {
    path.lineTo(offsetX, offsetY + height / 3 * 2);
    path.cubicTo(
      offsetX - bumpSize, offsetY + height / 6 * 5,
      offsetX - bumpSize, offsetY + height / 6,
      offsetX, offsetY + height / 3,
    );
    path.close();
  }

  return path;
}
