import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

const double cardRadiusValue = 10;
const Radius cardRadius = Radius.circular(cardRadiusValue);

const BorderRadius cardBorderRadius = BorderRadius.all(cardRadius);

const Color shadow = Color(0x1A000000);
const BoxShadow cardShadow =
    BoxShadow(color: shadow, blurRadius: 6, offset: Offset(0, 4));
const BoxDecoration defaultShadow = BoxDecoration(
  color: Colors.white,
  borderRadius: cardBorderRadius,
  boxShadow: [cardShadow],
);

const double buttonRadiusValue = 5;
const Radius buttonRadius = Radius.circular(buttonRadiusValue);
const BorderRadius buttonBorderRadius = BorderRadius.all(buttonRadius);
const OutlinedBorder buttonShapeBorder =
    RoundedRectangleBorder(borderRadius: buttonBorderRadius);

EdgeInsets inputPaddingPlatformSpecific() {
  if (kIsWeb) return const EdgeInsets.fromLTRB(14, 20, 14, 20);
  if (Platform.isMacOS || Platform.isWindows) {
    return const EdgeInsets.fromLTRB(12, 12, 12, 12);
  }
  return const EdgeInsets.fromLTRB(14, 14, 14, 14);
}

EdgeInsets buttonPaddingPlatformSpecific() {
  if (kIsWeb) return const EdgeInsets.symmetric(vertical: 20, horizontal: 20);
  if (Platform.isMacOS || Platform.isWindows) {
    return const EdgeInsets.symmetric(vertical: 20, horizontal: 20);
  }
  return const EdgeInsets.symmetric(vertical: 12, horizontal: 20);
}
