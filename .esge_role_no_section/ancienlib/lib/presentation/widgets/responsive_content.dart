import 'package:flutter/material.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: padding, child: child),
    ),
  );
}

int responsiveColumns(
  double width, {
  int phone = 2,
  int tablet = 3,
  int desktop = 4,
}) {
  if (width >= 1000) return desktop;
  if (width >= 650) return tablet;
  return phone;
}
