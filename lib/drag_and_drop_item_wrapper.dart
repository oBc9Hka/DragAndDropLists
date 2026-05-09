import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:drag_and_drop_lists/measure_size.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DragAndDropItemWrapper extends StatefulWidget {
  final DragAndDropItem child;
  final DragAndDropBuilderParameters? parameters;

  const DragAndDropItemWrapper(
      {required this.child, required this.parameters, super.key});

  @override
  State<StatefulWidget> createState() => _DragAndDropItemWrapper();
}

class _DragAndDropItemWrapper extends State<DragAndDropItemWrapper>
    with TickerProviderStateMixin {
  static final ValueNotifier<int> _activeItemDragCount = ValueNotifier<int>(0);
  DragAndDropItem? _hoveredDraggable;

  bool _dragging = false;
  bool _isItemHoveredOnWeb = false;
  Size _containerSize = Size.zero;
  Size _dragHandleSize = Size.zero;

  @override
  void dispose() {
    if (_dragging && _activeItemDragCount.value > 0) {
      _activeItemDragCount.value--;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget draggable;
    if (widget.child.canDrag) {
      if (widget.parameters!.itemDragHandle != null) {
        Widget feedback = SizedBox(
          width: widget.parameters!.itemDraggingWidth ?? _containerSize.width,
          child: Stack(
            children: [
              widget.child.child,
              Positioned(
                right: widget.parameters!.itemDragHandle!.onLeft ? null : 0,
                left: widget.parameters!.itemDragHandle!.onLeft ? 0 : null,
                top: widget.parameters!.itemDragHandle!.verticalAlignment ==
                        DragHandleVerticalAlignment.bottom
                    ? null
                    : 0,
                bottom: widget.parameters!.itemDragHandle!.verticalAlignment ==
                        DragHandleVerticalAlignment.top
                    ? null
                    : 0,
                child: widget.parameters!.itemDragHandle!,
              ),
            ],
          ),
        );

        var positionedDragHandle = Positioned(
          right: widget.parameters!.itemDragHandle!.onLeft ? null : 0,
          left: widget.parameters!.itemDragHandle!.onLeft ? 0 : null,
          top: widget.parameters!.itemDragHandle!.verticalAlignment ==
                  DragHandleVerticalAlignment.bottom
              ? null
              : 0,
          bottom: widget.parameters!.itemDragHandle!.verticalAlignment ==
                  DragHandleVerticalAlignment.top
              ? null
              : 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Draggable<DragAndDropItem>(
              data: widget.child,
              axis: widget.parameters!.axis == Axis.vertical &&
                      widget.parameters!.constrainDraggingAxis
                  ? Axis.vertical
                  : null,
              feedback: Transform.translate(
                offset: _feedbackContainerOffset(),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: widget.parameters!.itemDecorationWhileDragging,
                    child: Directionality(
                      textDirection: Directionality.of(context),
                      child: feedback,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Container(),
              onDragStarted: () => _setDragging(true),
              onDragCompleted: () => _setDragging(false),
              onDraggableCanceled: (_, __) => _setDragging(false),
              onDragEnd: (_) => _setDragging(false),
              child: MeasureSize(
                onSizeChange: (size) {
                  setState(() {
                    _dragHandleSize = size!;
                  });
                },
                child: widget.parameters!.itemDragHandle,
              ),
            ),
          ),
        );

        draggable = MeasureSize(
          onSizeChange: _setContainerSize,
          child: Stack(
            children: [
              Visibility(
                visible: !_dragging,
                child: widget.child.child,
              ),
              // dragAndDropListContents,
              positionedDragHandle,
            ],
          ),
        );
      } else if (widget.parameters!.dragOnLongPress && !kIsWeb) {
        draggable = MeasureSize(
          onSizeChange: _setContainerSize,
          child: LongPressDraggable<DragAndDropItem>(
            data: widget.child,
            axis: widget.parameters!.axis == Axis.vertical &&
                    widget.parameters!.constrainDraggingAxis
                ? Axis.vertical
                : null,
            feedback: SizedBox(
              width:
                  widget.parameters!.itemDraggingWidth ?? _containerSize.width,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: widget.parameters!.itemDecorationWhileDragging,
                  child: Directionality(
                      textDirection: Directionality.of(context),
                      child: widget.child.feedbackWidget ?? widget.child.child),
                ),
              ),
            ),
            childWhenDragging: Container(),
            onDragStarted: () => _setDragging(true),
            onDragCompleted: () => _setDragging(false),
            onDraggableCanceled: (_, __) => _setDragging(false),
            onDragEnd: (_) => _setDragging(false),
            child: widget.child.child,
          ),
        );
      } else {
        draggable = MeasureSize(
          onSizeChange: _setContainerSize,
          child: Draggable<DragAndDropItem>(
            data: widget.child,
            axis: widget.parameters!.axis == Axis.vertical &&
                    widget.parameters!.constrainDraggingAxis
                ? Axis.vertical
                : null,
            feedback: SizedBox(
              width:
                  widget.parameters!.itemDraggingWidth ?? _containerSize.width,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: widget.parameters!.itemDecorationWhileDragging,
                  child: Directionality(
                    textDirection: Directionality.of(context),
                    child: widget.child.feedbackWidget ?? widget.child.child,
                  ),
                ),
              ),
            ),
            childWhenDragging: Container(),
            onDragStarted: () => _setDragging(true),
            onDragCompleted: () => _setDragging(false),
            onDraggableCanceled: (_, __) => _setDragging(false),
            onDragEnd: (_) => _setDragging(false),
            child: widget.child.child,
          ),
        );
      }
    } else {
      draggable = AnimatedSize(
        duration: Duration(
            milliseconds: widget.parameters!.itemSizeAnimationDuration),
        alignment: Alignment.bottomCenter,
        child: _hoveredDraggable != null ? Container() : widget.child.child,
      );
    }
    final stack = Stack(
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.parameters!.verticalAlignment,
          children: <Widget>[
            AnimatedSize(
              duration: Duration(
                  milliseconds: widget.parameters!.itemSizeAnimationDuration),
              alignment: Alignment.topLeft,
              child: _hoveredDraggable != null
                  ? Opacity(
                      opacity: widget.parameters!.itemGhostOpacity,
                      child: widget.parameters!.itemGhost ??
                          _hoveredDraggable!.child,
                    )
                  : Container(),
            ),
            Listener(
              onPointerMove: _onPointerMove,
              onPointerDown: widget.parameters!.onPointerDown,
              onPointerUp: widget.parameters!.onPointerUp,
              child: _wrapDraggableForWeb(draggable),
            ),
          ],
        ),
        Positioned.fill(
          child: _wrapDragTargetForWeb(
            DragTarget<DragAndDropItem>(
              builder: (context, candidateData, rejectedData) {
                if (candidateData.isNotEmpty) {}
                return Container();
              },
              onWillAcceptWithDetails: (details) {
                bool accept = true;
                if (widget.parameters!.itemOnWillAccept != null) {
                  accept = widget.parameters!.itemOnWillAccept!(
                      details.data, widget.child);
                }
                if (accept && mounted) {
                  setState(() {
                    _hoveredDraggable = details.data;
                  });
                }
                return accept;
              },
              onLeave: (data) {
                if (mounted) {
                  setState(() {
                    _hoveredDraggable = null;
                  });
                }
              },
              onAcceptWithDetails: (details) {
                if (mounted) {
                  setState(() {
                    if (widget.parameters!.onItemReordered != null) {
                      widget.parameters!.onItemReordered!(
                        details.data,
                        widget.child,
                      );
                    }
                    _hoveredDraggable = null;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
    return _wrapItemStackForWeb(stack);
  }

  Offset _feedbackContainerOffset() {
    double xOffset;
    double yOffset;
    if (widget.parameters!.itemDragHandle!.onLeft) {
      xOffset = 0;
    } else {
      xOffset = -_containerSize.width + _dragHandleSize.width;
    }
    if (widget.parameters!.itemDragHandle!.verticalAlignment ==
        DragHandleVerticalAlignment.bottom) {
      yOffset = -_containerSize.height + _dragHandleSize.width;
    } else {
      yOffset = 0;
    }

    return Offset(xOffset, yOffset);
  }

  void _setContainerSize(Size? size) {
    if (mounted) {
      setState(() {
        _containerSize = size!;
      });
    }
  }

  void _setDragging(bool dragging) {
    if (_dragging != dragging && mounted) {
      setState(() {
        _dragging = dragging;
        if (dragging) {
          _isItemHoveredOnWeb = false;
        }
      });
      _updateActiveDragCount(dragging);
      if (widget.parameters!.onItemDraggingChanged != null) {
        widget.parameters!.onItemDraggingChanged!(widget.child, dragging);
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragging) widget.parameters!.onPointerMove!(event);
  }

  Widget _wrapDraggableForWeb(Widget draggable) {
    if (!kIsWeb || !widget.child.canDrag || widget.parameters!.itemDragHandle != null) {
      return draggable;
    }
    return ValueListenableBuilder<int>(
      valueListenable: _activeItemDragCount,
      builder: (context, activeDragCount, child) {
        final isAnyItemDragging = activeDragCount > 0;
        final isHovered = _isItemHoveredOnWeb &&
            !_dragging &&
            !isAnyItemDragging;
        final shouldHighlight =
            isHovered && widget.parameters!.itemHighlightOnHoverOnWeb;
        final cursor = _dragging
            ? widget.parameters!.itemDraggingMouseCursor
            : (isAnyItemDragging
                ? widget.parameters!.itemDraggingMouseCursor
                : widget.parameters!.itemMouseCursor);

        final hoverDecoration = widget.parameters!.itemDecorationOnHover ??
            BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            );

        return MouseRegion(
          cursor: cursor,
          opaque: true,
          onEnter: (_) => _setItemHoveredOnWeb(true),
          onExit: (_) => _setItemHoveredOnWeb(false),
          child: _dragging
              ? const SizedBox.shrink()
              : TweenAnimationBuilder<Decoration>(
                  duration: Duration(
                    milliseconds: widget
                        .parameters!.itemHoverAnimationDurationMilliseconds,
                  ),
                  curve: Curves.easeOut,
                  tween: DecorationTween(
                    begin: const BoxDecoration(),
                    end: shouldHighlight ? hoverDecoration : const BoxDecoration(),
                  ),
                  child: draggable,
                  builder: (context, decoration, child) {
                    return DecoratedBox(
                      decoration: decoration,
                      child: child,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _wrapItemStackForWeb(Widget child) {
    if (!kIsWeb || !widget.child.canDrag || widget.parameters!.itemDragHandle != null) {
      return child;
    }

    return ValueListenableBuilder<int>(
      valueListenable: _activeItemDragCount,
      builder: (context, activeDragCount, _) {
        final isAnyItemDragging = activeDragCount > 0;
        final cursor = _dragging
            ? widget.parameters!.itemDraggingMouseCursor
            : (isAnyItemDragging
                ? widget.parameters!.itemDraggingMouseCursor
                : widget.parameters!.itemMouseCursor);

        return MouseRegion(
          cursor: cursor,
          opaque: false,
          onEnter: (_) => _setItemHoveredOnWeb(true),
          onExit: (_) => _setItemHoveredOnWeb(false),
          child: child,
        );
      },
    );
  }

  Widget _wrapDragTargetForWeb(Widget child) {
    if (!kIsWeb || !widget.child.canDrag || widget.parameters!.itemDragHandle != null) {
      return child;
    }

    return ValueListenableBuilder<int>(
      valueListenable: _activeItemDragCount,
      builder: (context, activeDragCount, _) {
        final isAnyItemDragging = activeDragCount > 0;
        final cursor = isAnyItemDragging
            ? widget.parameters!.itemDraggingMouseCursor
            : widget.parameters!.itemMouseCursor;

        return MouseRegion(
          cursor: cursor,
          opaque: false,
          child: child,
        );
      },
    );
  }

  void _setItemHoveredOnWeb(bool hovered) {
    if (_isItemHoveredOnWeb != hovered && mounted) {
      setState(() {
        _isItemHoveredOnWeb = hovered;
      });
    }
  }

  void _updateActiveDragCount(bool dragging) {
    if (dragging) {
      _activeItemDragCount.value++;
    } else if (_activeItemDragCount.value > 0) {
      _activeItemDragCount.value--;
    }
  }
}
