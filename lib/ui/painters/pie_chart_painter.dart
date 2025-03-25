part of easy_pie_chart;

class _PieChartPainter extends CustomPainter {
  final List<double> pieValues;
  final bool showValue;
  final List<PieData> pies;
  final double total;
  final double startAngle;
  final PieType pieType;
  final StrokeCap borderEdge;
  final double gap;
  final String? centerText;
  final TextStyle? style;
  final TextStyle? centerStyle;
  final double borderWidth;
  final bool animateFromEnd;
  final int? tappedIndex;

  _PieChartPainter({
    required this.pieValues,
    required this.pies,
    required this.showValue,
    required this.total,
    required this.pieType,
    required this.gap,
    required this.startAngle,
    required this.borderEdge,
    required this.borderWidth,
    required this.animateFromEnd,
    this.centerText,
    this.style,
    this.centerStyle,
    this.tappedIndex,
  });

  late double sweepRadian;

  late double startAngleRadian;

  @override
  void paint(Canvas canvas, Size size) {
    // [startAngleRadian] is the point from where PieChart begins
    /// converting angle from degree to radian
    startAngleRadian = startAngle * (pi / 180);

    ///looping through pie values to draw arcs
    for (int i = 0; i < pieValues.length; i++) {
      /// If [animateFromEnd] is set to true, the pie will animate counterclockwise
      /// for the specified index, starting from the last index and decreasing sequentially.
      final int index = animateFromEnd ? pieValues.length - i - 1 : i;
      final int adjustIndex = index ~/ (gap == 0.0 ? 1 : 2);
      final isTapped = tappedIndex == adjustIndex;

      /// Obtaining the precise fraction of the current pieValues relative to the total sum of pieValues,
      /// and converting it into radians. A value of -1 indicates that
      /// the animation will be counterclockwise, while a value of 1 indicates a clockwise animation.
      sweepRadian = (animateFromEnd ? -1 : 1) * 2 * pi * (pieValues[index] / total);

      final isGap = gap > 0.0 && index % 2 != 0;

      /// if gap is greater than 0 and current index is not divisible,
      /// it means current pie is a gap arc so it color will be transparent
      drawPieArc(
        pieValues[index],
        isGap ? Colors.transparent : pies[adjustIndex].color,
        isGap ? null : pies[adjustIndex].gradient,
        size,
        canvas,
        isTapped,
      );

      /// If showValue is set to true, the pieValue may be displayed. Additionally,
      /// if gap equals 0.0 or if the index is divisible by a 2,
      /// then the value will be displayed.
      ///A gap value of 0.0 indicates the absence of gaps between each pie piece.
      ///The condition index % 2 == 0 will be satisfied when the gap value is greater than 0 and
      ///the index is divisible by 2. In such cases, the value will be displayed.
      if (showValue && !isGap) {
        showPieText(pies[adjustIndex].value, size.width / 2, size, canvas);
      }

      updateStartAngle();
    }
    if (centerText != null && centerText!.trim() != "") {
      drawCenterText(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void drawPieArc(double pieValue, Color? pieColor, Gradient? gradient, Size size, Canvas canvas, bool tapped) {
    // Draw the curved border for the partition
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius);
    final borderPaint = Paint()
      ..setColorOrGradient(pieColor, gradient, rect)

      /// If #pietype is set to PieType.fill,
      /// a filled pie will be drawn;
      /// otherwise, the pie will only have a border.
      ..style = pieType == PieType.fill ? PaintingStyle.fill : PaintingStyle.stroke

      /// Set border width
      ..strokeWidth = borderWidth + (tapped ? 0.2 * borderWidth : 0)
      ..strokeCap = borderEdge;
    canvas.drawArc(
      rect,
      startAngleRadian,
      sweepRadian,

      /// If [pieType] is set to "crust," the border will be placed on the outer layer of the pie chart.
      /// Otherwise, individual pie pieces will have borders on all sides.
      pieType == PieType.crust ? false : true,
      borderPaint,
    );
  }

  void showPieText(double pieValue, double radius, Size size, Canvas canvas) {
    /// Calculate text position at the center of the border partition
    final textAngle = startAngleRadian + (sweepRadian) / 2;

    // Adjusts the text position according to PieType
    final textRadius = radius - borderWidth / (pieType == PieType.crust ? 50 : 0.75);
    final textX = size.width / 2 + cos(textAngle) * textRadius;
    final textY = size.height / 2 + sin(textAngle) * textRadius;

    /// Draw text at the center of the border partition
    final textSpan = TextSpan(text: pieValue.toStringAsFixed(1), style: style ?? const TextStyle(color: Colors.black, fontSize: 8.0));
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(textX - textPainter.width / 2, textY - textPainter.height / 2));
  }

  updateStartAngle() {
    startAngleRadian += sweepRadian;
  }

  drawCenterText(Canvas canvas, Size size) {
    final textSpan = TextSpan(text: centerText, style: centerStyle ?? const TextStyle(color: Colors.black, fontSize: 20.0));
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width / 2) - (textPainter.width / 2), size.height / 2 - (textPainter.height / 2)));
  }
}

extension PaintExtension on Paint {
  void setColorOrGradient(Color? color, Gradient? gradient, Rect rect) {
    if (gradient != null) {
      this.color = Colors.black;
      shader = gradient.createShader(rect);
    } else {
      this.color = color ?? Colors.transparent;
      shader = null;
    }
  }
}
