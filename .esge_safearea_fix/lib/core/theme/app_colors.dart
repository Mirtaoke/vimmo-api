import 'package:flutter/material.dart';

/// ESGE visual system used by every role.
/// Role identity is expressed by content and permissions, never by a dedicated colour.
abstract final class AppColors {
  static const background = Color(0xFF071A14);
  static const background2 = Color(0xFF0A241B);
  static const navy = Color(0xFF0B281E);
  static const navyLight = Color(0xFF103B2D);
  static const surface = Color(0xFF10372A);
  static const surface2 = Color(0xFF154535);
  static const surface3 = Color(0xFF1B5944);
  static const line = Color(0xFF28634E);
  static const lineSoft = Color(0xFF1C4D3C);
  static const text = Color(0xFFF5FFF9);
  static const textSoft = Color(0xFFC2DDCF);
  static const muted = Color(0xFF8EB6A4);

  static const cyan = Color(0xFF62F29A);
  static const blue = Color(0xFF25D99B);
  static const violet = Color(0xFF16C784);
  static const violet2 = Color(0xFF82F7AD);
  static const aqua = Color(0xFF37E6B0);
  static const green = Color(0xFF72F0A0);
  static const yellow = Color(0xFFD5F36A);
  static const orange = Color(0xFFFF9E5A);
  static const red = Color(0xFFFF667A);

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
  static const lavender = Color(0xFF123D2F);
  static const mint = Color(0xFF103B30);
  static const cocoa = violet;
  static const espresso = background;
  static const sand = cyan;
  static const cream = Color(0xFF123229);
  static const soft = Color(0xFF0D2821);
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
    Color(0xFF16B978),
  ];

  static const actionGradient = <Color>[
    Color(0xFF16B978),
    Color(0xFF38DB91),
    Color(0xFF83F6A9),
  ];

  static const violetGradient = <Color>[
    Color(0xFF08714F),
    Color(0xFF16B978),
    Color(0xFF61E99B),
  ];

  static const softGradient = <Color>[Color(0xFF0B251E), Color(0xFF10352A)];
}
