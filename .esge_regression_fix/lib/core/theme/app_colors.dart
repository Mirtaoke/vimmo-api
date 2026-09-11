import 'package:flutter/material.dart';

/// ESGE visual system used by every role.
/// Role identity is expressed by content and permissions, never by a dedicated colour.
abstract final class AppColors {
  static const background = Color(0xFFF3FAF6);
  static const background2 = Color(0xFFE8F5EE);
  static const navy = Color(0xFF0B281E);
  static const navyLight = Color(0xFF103B2D);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFE4F4EB);
  static const surface3 = Color(0xFFCDEAD9);
  static const line = Color(0xFFD2E7DA);
  static const lineSoft = Color(0xFFE1EFE7);
  static const text = Color(0xFF10251C);
  static const textSoft = Color(0xFF4E7060);
  static const muted = Color(0xFF799487);

  static const cyan = Color(0xFF3EAD79);
  static const blue = Color(0xFF358F72);
  static const violet = Color(0xFF278D63);
  static const violet2 = Color(0xFF75C996);
  static const aqua = Color(0xFF52B991);
  static const green = Color(0xFF63C98B);
  static const yellow = Color(0xFFC3D96B);
  static const orange = Color(0xFFFF9E5A);
  static const red = Color(0xFFFF667A);
  static const indigo = Color(0xFF5968B0);
  static const plum = Color(0xFF9B5C8F);

  static const primary = cyan;
  static const secondary = violet;
  static const success = green;
  static const warning = yellow;
  static const danger = red;
  static const info = blue;
  static const gold = yellow;
  static const coral = red;
  static const lime = green;
  static const teal = aqua;
  static const tealDark = Color(0xFF0D807D);
  static const appPurple = violet;
  static const appPurpleDark = Color(0xFF075B43);
  static const peach = orange;
  static const lavender = Color(0xFFE0F7E9);
  static const mint = Color(0xFFD9F6E5);
  static const cocoa = violet;
  static const espresso = background;
  static const sand = cyan;
  static const cream = Color(0xFFF1FAF4);
  static const soft = Color(0xFFEAF6EF);
  static const canvas = background;
  static const connectedCanvas = background;
  static const workspace = background;
  static const workspaceLight = surface;
  static const ink = text;
  static const charcoal = surface2;
  static const warmDark = background2;

  static const heroGradient = <Color>[
    Color(0xFF061A14),
    Color(0xFF07583F),
    Color(0xFF23835D),
  ];

  static const actionGradient = <Color>[
    Color(0xFF278D63),
    Color(0xFF52B982),
    Color(0xFF9ACE79),
  ];

  static const violetGradient = <Color>[
    Color(0xFF176647),
    Color(0xFF318D65),
    Color(0xFF72BE8E),
  ];

  static const softGradient = <Color>[Color(0xFFF9FFFB), Color(0xFFE8F6EE)];
}
