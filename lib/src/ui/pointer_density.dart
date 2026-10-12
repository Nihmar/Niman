import 'package:flutter/material.dart';

/// Whether [theme] is drawn for a pointer rather than a thumb (#296).
///
/// Flutter's adaptive density is compact on Windows and Linux and standard
/// on a phone or a tablet, so the platform answers through the theme: lists
/// and menus that a mouse aims at can be tighter than ones a finger has to
/// hit, and a test can ask for either by setting the density.
bool pointerDense(ThemeData theme) => theme.visualDensity.vertical < 0;

/// The row metrics a pointer's menus use (#296): the phone's 48 px items
/// run thirteen entries most of a screen tall, for a cursor that needs a
/// third of the room. The tree's row menus and the footer's own read them.
const double pointerDenseItemHeight = 32;

/// The divider between two groups of a pointer's menu: the phone's 16 px
/// of air between two rows a mouse reads in one look.
const double pointerDenseDividerHeight = 9;

/// The room a pointer's menu keeps above its first row and below its last.
const EdgeInsets pointerDenseMenuPadding = EdgeInsets.symmetric(vertical: 4);
