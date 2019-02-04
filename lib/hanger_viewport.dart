import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'dart:math' as math;

class HangerParentData extends ContainerBoxParentData<RenderBox> {
  int index;
}

class RenderHangerViewport extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ListWheelParentData>
    implements RenderAbstractViewport {
  RenderHangerViewport({
    this.childManager,
    @required ViewportOffset offset,
    @required double itemExtent,
  })  : assert(childManager != null),
        assert(offset != null),
        assert(itemExtent != null && itemExtent >= 0),
        _offset = offset,
        _itemExtent = itemExtent;

  final ListWheelChildManager childManager;

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset) return;
    _offset = value;
    markNeedsLayout();
  }

  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    assert(value != null);
    assert(value > 0);
    if (value == _itemExtent) return;
    _itemExtent = value;
    markNeedsLayout();
  }

  void _hasScrolled() {
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! ListWheelParentData)
      child.parentData = ListWheelParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_hasScrolled);
  }

  @override
  void detach() {
    _offset.removeListener(_hasScrolled);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  /// Main axis length in the untransformed plane.
  double get _viewportExtent {
    assert(hasSize);
    return size.width;
  }

  /// Main axis scroll extent in the **scrollable layout coordinates** that puts
  /// the first item in the center.
  double get _minEstimatedScrollExtent {
    assert(hasSize);
    if (childManager.childCount == null) return double.negativeInfinity;
    return 0.0;
  }

  /// Main axis scroll extent in the **scrollable layout coordinates** that puts
  /// the last item in the center.
  double get _maxEstimatedScrollExtent {
    assert(hasSize);
    if (childManager.childCount == null) return double.infinity;

    return math.max(0.0, (childManager.childCount - 1) * _itemExtent);
  }

  /// Gets the index of a child by looking at its parentData.
  int indexOf(RenderBox child) {
    assert(child != null);
    final HangerParentData childParentData = child.parentData;
    assert(childParentData.index != null);
    return childParentData.index;
  }

  /// Returns the index of the child at the given offset.
  int scrollOffsetToIndex(double scrollOffset) =>
      (scrollOffset / itemExtent).floor();

  /// Returns the scroll offset of the child with the given index.
  double indexToScrollOffset(int index) => index * itemExtent;

  void _createChild(int index, {RenderBox after}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.createChild(index, after: after);
    });
  }

  void _destroyChild(RenderBox child) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.removeChild(child);
    });
  }

  void _layoutChild(RenderBox child, BoxConstraints constraints, int index) {
    child.layout(constraints, parentUsesSize: true);
    final ListWheelParentData childParentData = child.parentData;
    // Centers the child vertically.
    final double crossPosition = size.height / 2.0 - child.size.height / 2.0;
    childParentData.offset = Offset(crossPosition, indexToScrollOffset(index));
  }

  /// Performs layout based on how [childManager] provides children.
  ///
  /// From the current scroll offset, the minimum index and maximum index that
  /// is visible in the viewport can be calculated. The index range of the
  /// currently active children can also be acquired by looking directly at
  /// the current child list. This function has to modify the current index
  /// range to match the target index range by removing children that are no
  /// longer visible and creating those that are visible but not yet provided
  /// by [childManager].
  @override
  void performLayout() {
    final BoxConstraints childConstraints = constraints.copyWith(
      minWidth: _itemExtent,
      maxWidth: _itemExtent,
      minHeight: 0.0,
    );

    // The height, in pixel, that children will be visible and might be laid out
    // and painted.
    double visibleWidth = size.width;

    final double firstVisibleOffset =
        offset.pixels + _itemExtent / 2 - visibleWidth / 2;
    final double lastVisibleOffset = firstVisibleOffset + visibleWidth;

    // The index range that we want to spawn children. We find indexes that
    // are in the interval [firstVisibleOffset, lastVisibleOffset).
    int targetFirstIndex = scrollOffsetToIndex(firstVisibleOffset);
    int targetLastIndex = scrollOffsetToIndex(lastVisibleOffset);
    // Because we exclude lastVisibleOffset, if there's a new child starting at
    // that offset, it is removed.
    if (targetLastIndex * _itemExtent == lastVisibleOffset) targetLastIndex--;

    // Validates the target index range.
    while (!childManager.childExistsAt(targetFirstIndex) &&
        targetFirstIndex <= targetLastIndex) targetFirstIndex++;
    while (!childManager.childExistsAt(targetLastIndex) &&
        targetFirstIndex <= targetLastIndex) targetLastIndex--;

    // If it turns out there's no children to layout, we remove old children and
    // return.
    if (targetFirstIndex > targetLastIndex) {
      while (firstChild != null) _destroyChild(firstChild);
      return;
    }

    // Now there are 2 cases:
    //  - The target index range and our current index range have intersection:
    //    We shorten and extend our current child list so that the two lists
    //    match. Most of the time we are in this case.
    //  - The target list and our current child list have no intersection:
    //    We first remove all children and then add one child from the target
    //    list => this case becomes the other case.

    // Case when there is no intersection.
    if (childCount > 0 &&
        (indexOf(firstChild) > targetLastIndex ||
            indexOf(lastChild) < targetFirstIndex)) {
      while (firstChild != null) _destroyChild(firstChild);
    }

    // If there is no child at this stage, we add the first one that is in
    // target range.
    if (childCount == 0) {
      _createChild(targetFirstIndex);
      _layoutChild(firstChild, childConstraints, targetFirstIndex);
    }

    int currentFirstIndex = indexOf(firstChild);
    int currentLastIndex = indexOf(lastChild);

    // Remove all unnecessary children by shortening the current child list, in
    // both directions.
    while (currentFirstIndex < targetFirstIndex) {
      _destroyChild(firstChild);
      currentFirstIndex++;
    }
    while (currentLastIndex > targetLastIndex) {
      _destroyChild(lastChild);
      currentLastIndex--;
    }

    // Relayout all active children.
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      child = childAfter(child);
    }

    // Spawning new children that are actually visible but not in child list yet.
    while (currentFirstIndex > targetFirstIndex) {
      _createChild(currentFirstIndex - 1);
      _layoutChild(firstChild, childConstraints, --currentFirstIndex);
    }
    while (currentLastIndex < targetLastIndex) {
      _createChild(currentLastIndex + 1, after: lastChild);
      _layoutChild(lastChild, childConstraints, ++currentLastIndex);
    }

    offset.applyViewportDimension(_viewportExtent);

    // Applying content dimensions bases on how the childManager builds widgets:
    // if it is available to provide a child just out of target range, then
    // we don't know whether there's a limit yet, and set the dimension to the
    // estimated value. Otherwise, we set the dimension limited to our target
    // range.
    final double minScrollExtent =
        childManager.childExistsAt(targetFirstIndex - 1)
            ? _minEstimatedScrollExtent
            : indexToScrollOffset(targetFirstIndex);
    final double maxScrollExtent =
        childManager.childExistsAt(targetLastIndex + 1)
            ? _maxEstimatedScrollExtent
            : indexToScrollOffset(targetLastIndex);
    offset.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (childCount > 0) {
      _paintVisibleChildren(context, offset);
    }
  }

  /// Paints all children visible in the current viewport.
  void _paintVisibleChildren(PaintingContext context, Offset offset) {
    RenderBox childToPaint = firstChild;
    HangerParentData childParentData = childToPaint?.parentData;

    while (childParentData != null) {
      _paintTransformedChild(
          childToPaint, context, offset, childParentData.offset);
      childToPaint = childAfter(childToPaint);
      childParentData = childToPaint?.parentData;
    }
  }

  /// Takes in a child with a **scrollable layout offset** and paints it in the
  /// **transformed cylindrical space viewport painting coordinates**.
  void _paintTransformedChild(
    RenderBox child,
    PaintingContext context,
    Offset offset,
    Offset layoutOffset,
  ) {
    final Offset untransformedPaintingCoordinates = offset +
        Offset(
          layoutOffset.dx,
//            _getUntransformedPaintingCoordinateY(layoutOffset.dy),
          layoutOffset.dy,
        );

    // Get child's center as a fraction of the viewport's height.
    final double fractionalY =
        (untransformedPaintingCoordinates.dy + _itemExtent / 2.0) / size.height;
    final double angle = -(fractionalY - 0.5) * 2.0 * _maxVisibleRadian;
    // Don't paint the backside of the cylinder when
    // renderChildrenOutsideViewport is true. Otherwise, only children within
    // suitable angles (via _first/lastVisibleLayoutOffset) reach the paint
    // phase.
    if (angle > math.pi / 2.0 || angle < -math.pi / 2.0) return;

    final Matrix4 transform = MatrixUtils.createCylindricalProjectionTransform(
      radius: size.height * _diameterRatio / 2.0,
      angle: angle,
      perspective: _perspective,
    );

    // Offset that helps painting everything in the center (e.g. angle = 0).
    final Offset offsetToCenter =
        Offset(untransformedPaintingCoordinates.dx, -_topScrollMarginExtent);

    if (!useMagnifier)
      _paintChildCylindrically(
          context, offset, child, transform, offsetToCenter);
    else
      _paintChildWithMagnifier(
        context,
        offset,
        child,
        transform,
        offsetToCenter,
        untransformedPaintingCoordinates,
      );
  }

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment,
      {Rect rect}) {
    // TODO: implement getOffsetToReveal
    return null;
  }
}
