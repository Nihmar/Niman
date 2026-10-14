import 'package:flutter/material.dart';

/// Whether [theme] is drawn for a pointer rather than a thumb (#296).
///
/// Flutter's adaptive density is compact on Windows and Linux and standard
/// on a phone or a tablet, so the platform answers through the theme: lists
/// and menus that a mouse aims at can be tighter than ones a finger has to
/// hit, and a test can ask for either by setting the density.
bool pointerDense(ThemeData theme) => theme.visualDensity.vertical < 0;

/// Whether [theme] is drawn for a thumb: the platform's own density is
/// standard, not compact (#849). The wide shell on an Android tablet has
/// the desktop's chrome, and this is what turns its small targets into
/// thumb-sized ones while a mouse's stay as drawn.
bool thumbDense(ThemeData theme) => !pointerDense(theme);

/// The least a thumb's target measures on a side: Material's 48 dp.
const double thumbTarget = kMinInteractiveDimension;
