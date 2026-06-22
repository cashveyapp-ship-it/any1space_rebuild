import 'package:flutter/material.dart';

class ResponsivePage extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool scrollable;

  const ResponsivePage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final wrapped = Padding(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        padding.top + safe.top,
        padding.right,
        padding.bottom + safe.bottom + bottomInset,
      ),
      child: child,
    );

    if (!scrollable) return wrapped;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: wrapped,
          ),
        );
      },
    );
  }
}
