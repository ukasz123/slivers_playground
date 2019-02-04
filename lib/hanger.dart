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
    final alpha = math.pi / 36;

    final rotation = distanceFromMiddle * alpha;

    final maxCrossAxisTranslation = constraints.viewportMainAxisExtent *
        0.5 *
        ((1 - math.cos(alpha)) / math.sin(alpha));
    final crossAxisTranslation =
        (1 - distanceFromMiddle.abs()) * maxCrossAxisTranslation;

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

    Offset translation;
    Offset alignment;
    switch (constraints.axis) {
      case Axis.horizontal:
        translation = Offset(0.0, crossAxisTranslation);
        alignment = Offset(0.0, 1.0);
        break;
      case Axis.vertical:
        translation = Offset(crossAxisTranslation, 0.0);
        alignment = Offset(1.0, 0.0);
        break;
    }

    final SliverHangerParentData childParentData = child.parentData;
    childParentData.rotation = rotation;
    childParentData.translation = translation;
    childParentData.size = Size(paintedChildSize, crossAxisChildExtent);
    childParentData.alignment = alignment;
    print(
        "distanceFromMiddle = $distanceFromMiddle, rotation = ${childParentData.rotation}, translationY = ${childParentData.translation}, size = ${childParentData.size}");
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
                -childParentData.size.width / 2 * childParentData.alignment.dx,
                -childParentData.size.height / 2 * childParentData.alignment.dy)
            ..rotateZ(childParentData.rotation)
            ..translate(childParentData.translation.dx,
                childParentData.translation.dy, 0.0)
            ..translate(
                childParentData.size.width / 2 * childParentData.alignment.dx,
                childParentData.size.height / 2 * childParentData.alignment.dy),
          (context, offset) {
        context.paintChild(child, offset);
      });
    }
  }
}

class SliverHangerParentData extends SliverPhysicalParentData {
  double rotation = 0.0;
  Offset translation = Offset.zero;

  Size size;

  Offset alignment;

  @override
  void applyPaintTransform(Matrix4 transform) {
    super.applyPaintTransform(transform);
  }
}
