import 'package:flutter/material.dart';

import 'ui_constants.dart';

class LoadingButton extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double? borderRadius;
  final TextStyle? style;
  final EdgeInsets? padding;
  final Color? color;
  final double? loaderSize;

  const LoadingButton({
    super.key,
    required this.title,
    this.isLoading = false,
    this.onPressed,
    this.borderRadius,
    this.style,
    this.padding,
    this.color,
    this.loaderSize,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(buttonRadius),
      ),
      backgroundColor: color,
      padding: padding ?? buttonPaddingPlatformSpecific(),
      elevation: 0,
      textStyle: Theme.of(context)
          .textTheme
          .labelLarge!
          .copyWith(fontWeight: FontWeight.normal)
          .merge(this.style),
    );
    if (!isLoading) {
      return ElevatedButton(
        style: style,
        onPressed: onPressed,
        child: Text(title),
      );
    }
    return ElevatedButton.icon(
      style: style,
      icon: isLoading
          ? SizedBox.square(
              dimension: loaderSize ?? 24,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            )
          : const SizedBox(height: 24, width: 0),
      label: Text(title),
      onPressed: () {},
    );
  }
}
