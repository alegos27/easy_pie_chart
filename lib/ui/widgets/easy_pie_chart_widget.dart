part of easy_pie_chart;

class EasyPieChart extends StatelessWidget {
  /// Represents a list of [PieData] objects, where each [PieData] holds a value and a color.
  /// The pie chart will be divided into partitions, each corresponding to an item in [children].
  ///
  /// Example usage:
  /// ```dart
  /// PieChart(
  ///   children: [
  ///     PieData(value: 30, color: Colors.red),
  ///     PieData(value: 50, color: Colors.blue),
  ///   ],
  /// )
  /// ```
  final List<PieData> children;

  /// The [TextStyle] applied to the value displayed on each pie data.
  final TextStyle? style;

  /// Determines whether the value is shown on each pie slice. Defaults to true.
  final bool showValue;

  /// The starting angle of the pie chart in degrees. Default is -90, which represents CenterTop.
  /// 0 represents CenterRight, 90 represents CenterBottom, and 180 represents CenterLeft.
  final double start;

  /// Text to be displayed at the center of the pie chart. If null, center text is not shown.
  final String? centerText;

  /// [TextStyle] for the [centerText].
  final TextStyle? centerStyle;

  /// Enum defining the pie chart type:
  /// - [PieType.crust]: Only border, no fill.
  /// - [PieType.triCrust]: Borders around each pie slice.
  /// - [PieType.fill]: Filled pie slices.
  final PieType pieType;

  /// A widget that is displayed inside the pie chart. Overrides [centerText].
  final Widget? child;

  /// The size of the pie chart. Default value is 200.
  final double size;

  /// Gap between pie chart slices. Default value is 0.0 (no gap).
  final double gap;

  /// The width of the border for [PieType.crust] and [PieType.triCrust]. Default is 30.0.
  final double borderWidth;

  /// Defines the edge shape of the border for [PieType.crust].
  /// Applicable values: [StrokeCap.butt], [StrokeCap.round], [StrokeCap.square].
  final StrokeCap borderEdge;

  /// If true, the pie chart animates clockwise during build. Default is true.
  final bool shouldAnimate;

  /// Duration of the animation. Default is 1000 milliseconds.
  final Duration? animateDuration;

  /// If true, animation starts anti-clockwise. Default is false.
  final bool animateFromEnd;

  final Size? badgeSize;

  final Widget Function(BuildContext context, int index)? badgeBuilder;

  /// Function triggered when a pie slice is tapped. Provides the index of the pie value.
  final void Function(int? index)? onTap;

  final int? selectedIndex;

  const EasyPieChart({
    Key? key,
    required this.children,
    this.showValue = true,
    this.start = -90,
    this.gap = 0.0,
    this.borderWidth = 20.0,
    this.borderEdge = StrokeCap.round,
    this.shouldAnimate = true,
    this.animateDuration,
    this.centerText,
    this.child,
    this.style,
    this.centerStyle,
    this.animateFromEnd = false,
    this.pieType = PieType.crust,
    this.size = 200,
    this.badgeSize,
    this.badgeBuilder,
    this.selectedIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<double> pieValues = getValues(children, gap);
    final double total = pieValues.reduce(((value, element) => value + element));

    return shouldAnimate
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.00000000001, end: 1.0),
            duration: animateDuration ?? const Duration(milliseconds: 1500),
            builder: (context, value, _) {
              return pieChartWidget(pieValues, total, value, context);
            })
        : pieChartWidget(pieValues, total, 1, context);
  }

  Widget pieChartWidget(List<double> pieValues, double total, double value, BuildContext context) {
    return GestureDetector(
      onTapUp: onTap == null
          ? null
          : (details) {
              int? tappedIndex;
              final int? index = getIndexOfTappedPie(
                  pieValues, total, gap, getAngleIn360(start), getAngleFromCordinates(details.localPosition.dx, details.localPosition.dy, size / 2));
              if (index != null) {
                if (tappedIndex == index) {
                  tappedIndex = null;
                } else {
                  tappedIndex = index;
                }
              } else {
                tappedIndex = null;
              }
              onTap!(tappedIndex);
            },
      child: SizedBox(
        height: size,
        width: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _PieChartPainter(
                pies: children,
                pieValues: pieValues.map((pieValue) => pieValue * value).toList(),
                total: total,
                showValue: showValue,
                startAngle: start,
                pieType: pieType,
                animateFromEnd: animateFromEnd,
                centerText: child != null ? null : centerText,
                style: style,
                centerStyle: centerStyle,
                gap: gap,
                borderEdge: borderEdge,
                borderWidth: borderWidth,
                tappedIndex: selectedIndex,
              ),
              child: child,
            ),
            _getBadge(context)
          ],
        ),
      ),
    );
  }

  Widget _getBadge(BuildContext context) {
    if (badgeBuilder != null && selectedIndex != null) {
      final badgePosition = getBadgeStartPoint(
        selectedIndex!,
        children.map((pie) => pie.value).toList(),
        getAngleIn360(start),
        size / 2,
        badgeSize!,
      );
      double left = badgePosition.dx;
      double top = badgePosition.dy;
      if (left < 0) {
        left = 0;
      }
      if (left + (badgeSize?.width ?? 0) > size) {
        left = size - (badgeSize?.width ?? 0);
      }
      if (top < 0) {
        top = 0;
      }
      if (top + (badgeSize?.height ?? 0) > size) {
        top = size - (badgeSize?.height ?? 0);
      }
      return Positioned(
        left: left,
        top: top,
        child: badgeBuilder!(context, selectedIndex!),
      );
    }
    return const SizedBox.shrink();
  }
}
