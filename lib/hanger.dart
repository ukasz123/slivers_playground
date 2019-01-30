import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

class SliverHanger extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.
  const SliverHanger({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverHanger createRenderObject(BuildContext context) =>
      RenderSliverHanger();
}

class RenderSliverHanger extends RenderSliverToBoxAdapter {
  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    var boxConstraints = constraints.asBoxConstraints();
    switch (constraints.axis) {
      case Axis.horizontal:
        boxConstraints = boxConstraints.copyWith(minHeight: 0.0);
        break;
      case Axis.vertical:
        boxConstraints = boxConstraints.copyWith(minWidth: 0.0);
        break;
    }
    child.layout(boxConstraints, parentUsesSize: true);
    double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child.size.width;
        break;
      case Axis.vertical:
        childExtent = child.size.height;
        break;
    }
    assert(childExtent != null);
    double crossAxisChildExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        crossAxisChildExtent = child.size.height;
        break;
      case Axis.vertical:
        crossAxisChildExtent = child.size.width;
        break;
    }
    assert(crossAxisChildExtent != null);
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent =
        calculateCacheOffset(constraints, from: 0.0, to: childExtent);

    final distanceFromEnd =
        (constraints.remainingPaintExtent - 0.5 * paintedChildSize) /
            constraints.viewportMainAxisExtent;
    final distanceFromMiddle = distanceFromEnd - 0.5;
    final rotation = distanceFromMiddle * math.pi / 180 * 15;

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
    setChildParentData(child, constraints, geometry);

    final SliverHangerParentData childParentData = child.parentData;
    childParentData.rotation = rotation;
    childParentData.translationY =
        (0.5 - abs(distanceFromMiddle)) * crossAxisChildExtent * 0.1;
    childParentData.size = Size(paintedChildSize, crossAxisChildExtent);
    print(
        "rotation = ${childParentData.rotation}, translationY = ${childParentData.translationY}, size = ${childParentData.size}");
  }

  double abs(double v) => v < 0 ? -v : v;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverHangerParentData)
      child.parentData = SliverHangerParentData();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry.visible) {
      final SliverHangerParentData childParentData = child.parentData;
      context.pushTransform(
          true,
          childParentData.paintOffset + offset,
          Matrix4.identity()
            ..translate(
                childParentData.size.width / 2, childParentData.size.height / 2)
            ..translate(0.0, childParentData.translationY ?? 0.0, 0.0)
            ..rotateZ(childParentData.rotation)
            ..translate(-childParentData.size.width / 2,
                -childParentData.size.height / 2), (context, offset) {
        context.paintChild(child, offset);
      });
    }
  }
}

class SliverHangerParentData extends SliverPhysicalParentData {
  double rotation = 0.0;
  double translationY = 0.0;

  Size size;

  @override
  void applyPaintTransform(Matrix4 transform) {
    super.applyPaintTransform(transform);
  }
}
