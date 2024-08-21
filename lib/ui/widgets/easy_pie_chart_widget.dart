part of easy_pie_chart;

class EasyPieChart extends StatefulWidget {
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
  final void Function(int index)? onTap;
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
    this.onTap,
    this.size = 200,
    this.badgeSize,
    this.badgeBuilder,
  }) : super(key: key);

  @override
  State<EasyPieChart> createState() => _EasyPieChartState();
}

class _EasyPieChartState extends State<EasyPieChart> {
  final OverlayPortalController _tooltipController = OverlayPortalController();
  Offset? _tooltipPosition;
  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    final List<double> pieValues = getValues(widget.children, widget.gap);
    final double total = pieValues.reduce(((value, element) => value + element));

    return widget.shouldAnimate
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.00000000001, end: 1.0),
            duration: widget.animateDuration ?? const Duration(milliseconds: 1500),
            builder: (context, value, _) {
              return pieChartWidget(pieValues, total, value);
            })
        : pieChartWidget(pieValues, total, 1);
  }

  Widget pieChartWidget(List<double> pieValues, double total, double value) {
    return GestureDetector(
      onTapUp: widget.onTap == null
          ? null
          : (details) {
              double kX = details.globalPosition.dx - details.localPosition.dx;
              double kY = details.globalPosition.dy - details.localPosition.dy;
              final int? index = getIndexOfTappedPie(
                  pieValues, total, widget.gap, getAngleIn360(widget.start), getAngleFromCordinates(details.localPosition.dx, details.localPosition.dy, widget.size / 2));
              if (index != null) {
                widget.onTap!(index);
                if (_tappedIndex == index) {
                  setState(() {
                    _tappedIndex = null;
                  });
                  _tooltipPosition = null;
                  _tooltipController.hide();
                } else {
                  setState(() {
                    _tappedIndex = index;
                  });
                  _tooltipPosition = getArcCenter(widget.start, widget.children.map((pie) => pie.value).toList(), widget.size / 2, index).translate(kX, kY);
                  _tooltipController.show();
                }
              } else {
                setState(() {
                  _tappedIndex = null;
                });
                _tooltipPosition = null;
                _tooltipController.hide();
              }
            },
      child: OverlayPortal(
        controller: _tooltipController,
        overlayChildBuilder: (context) {
          if (widget.badgeBuilder != null && _tappedIndex != null) {
            double left = (_tooltipPosition?.dx ?? 0) - (widget.badgeSize?.width ?? 0) / 2;
            double top = (_tooltipPosition?.dy ?? 0) - (widget.badgeSize?.height ?? 0) / 2;
            if (left < 0) {
              left = 0;
            }
            if (left + (widget.badgeSize?.width ?? 0) > MediaQuery.of(context).size.width) {
              left = MediaQuery.of(context).size.width - (widget.badgeSize?.width ?? 0);
            }
            if (top < 0) {
              top = 0;
            }
            if (top + (widget.badgeSize?.height ?? 0) > MediaQuery.of(context).size.height) {
              top = MediaQuery.of(context).size.height - (widget.badgeSize?.height ?? 0);
            }
            return Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _tappedIndex = null;
                  });
                  _tooltipPosition = null;
                  _tooltipController.hide();
                },
                child: widget.badgeBuilder!(context, _tappedIndex!),
              ),
            );
          }

          return const SizedBox.shrink();
        },
        child: SizedBox(
          height: widget.size,
          width: widget.size,
          child: CustomPaint(
            painter: _PieChartPainter(
              pies: widget.children,
              pieValues: pieValues.map((pieValue) => pieValue * value).toList(),
              total: total,
              showValue: widget.showValue,
              startAngle: widget.start,
              pieType: widget.pieType,
              animateFromEnd: widget.animateFromEnd,
              centerText: widget.child != null ? null : widget.centerText,
              style: widget.style,
              centerStyle: widget.centerStyle,
              gap: widget.gap,
              borderEdge: widget.borderEdge,
              borderWidth: widget.borderWidth,
              tappedIndex: _tappedIndex,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
