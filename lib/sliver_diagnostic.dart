import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliverMetadata {
  final Map<String, double> constraintsData;
  final Map<String, double> geometryData;

  SliverMetadata(this.constraintsData, this.geometryData);
}

/// Streams constraints and geometry of the child sliver
/// [SliverMetadata] objects are send to [onDiagnosticData] callback on each
/// layout invocation
class SliverDiagnostic extends SingleChildRenderObjectWidget {
  final ValueChanged<SliverMetadata> onDiagnosticData;

  SliverDiagnostic({this.onDiagnosticData, Key key, Widget sliver})
      : super(key: key, child: sliver);

  @override
  RenderSliverDiagnostic createRenderObject(BuildContext context) {
    return RenderSliverDiagnostic(onDiagnosticData: onDiagnosticData);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverDiagnostic renderObject) {
    super.updateRenderObject(context, renderObject);
    renderObject.onDiagnosticData = onDiagnosticData;
  }
}

class RenderSliverDiagnostic extends RenderSliver
    with RenderObjectWithChildMixin<RenderSliver> {
  ValueChanged<SliverMetadata> onDiagnosticData;

  RenderSliverDiagnostic({
    RenderSliver child,
    ValueChanged<SliverMetadata> onDiagnosticData,
  }) {
    this.child = child;
    this.onDiagnosticData = onDiagnosticData;
  }

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    } else {
      child.layout(constraints, parentUsesSize: true);
      geometry = child.geometry;
    }
    if (onDiagnosticData != null) {
      Map<String, double> constraintsMeta = {
        "scrollOffset": constraints.scrollOffset,
        "viewportMainAxisExtent": constraints.viewportMainAxisExtent,
        "cacheOrigin": constraints.cacheOrigin,
        "crossAxisExtent": constraints.crossAxisExtent,
        "overlap": constraints.overlap,
        "remainingCacheExtent": constraints.remainingCacheExtent,
        "remainingPaintExtent": constraints.remainingPaintExtent,
      };
      Map<String, double> geometryMeta = {
        "cacheExtent": geometry.cacheExtent,
        "layoutExtent": geometry.layoutExtent,
        "paintExtent": geometry.paintExtent,
        "paintOrigin": geometry.paintOrigin,
        "scrollExtent": geometry.scrollExtent,
        "maxPaintExtent": geometry.maxPaintExtent,
      };
      onDiagnosticData(SliverMetadata(constraintsMeta, geometryMeta));
    }
  }

  @override
  bool hitTestChildren(HitTestResult result,
      {double mainAxisPosition, double crossAxisPosition}) {
    return child?.hitTest(result,
            mainAxisPosition: mainAxisPosition,
            crossAxisPosition: crossAxisPosition) ??
        false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child.geometry.visible) {
      child.paint(context, offset);
    }
  }
}
