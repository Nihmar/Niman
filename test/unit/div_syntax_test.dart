import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/div_syntax.dart';
import 'package:niman/src/markdown/line_state.dart';

void main() {
  test('an opener is colons and a class word or braced attributes', () {
    expect(DivSyntax.opening(':::: columns')?.kind, DivKind.columns);
    expect(DivSyntax.opening('::: column')?.kind, DivKind.column);
    expect(DivSyntax.opening('::: {.columns}')?.kind, DivKind.columns);
    expect(DivSyntax.opening(':::{.column}')?.kind, DivKind.column);
    expect(DivSyntax.opening('::: warning')?.kind, DivKind.other);
    expect(DivSyntax.opening('::: {#id .note}')?.kind, DivKind.other);
    // Trailing colons are optional. A fence stands at its container's
    // margin, as Pandoc reads one: indented, it is text.
    expect(DivSyntax.opening('::: column :::')?.kind, DivKind.column);
    expect(DivSyntax.opening(' ::: column'), isNull);
    // Two colons, no class, two words: no opener.
    expect(DivSyntax.opening(':: column'), isNull);
    expect(DivSyntax.opening(':::'), isNull);
    expect(DivSyntax.opening('::: two words'), isNull);
    expect(DivSyntax.opening('text ::: column'), isNull);
  });

  test("a column's width is a percentage, quoted or not", () {
    expect(DivSyntax.opening('::: {.column width="40%"}')?.width, 40);
    expect(DivSyntax.opening('::: {.column width=40%}')?.width, 40);
    expect(DivSyntax.opening("::: {.column width='12.5%'}")?.width, 12.5);
    // Anything else shares like no width.
    expect(DivSyntax.opening('::: {.column width="300px"}')?.width, isNull);
    expect(DivSyntax.opening('::: {.column width="40"}')?.width, isNull);
    expect(DivSyntax.opening('::: {.column width="0%"}')?.width, isNull);
    expect(DivSyntax.opening('::: column')?.width, isNull);
  });

  test('a closer is three colons or more and nothing else', () {
    expect(DivSyntax.closes(':::'), isTrue);
    expect(DivSyntax.closes('::::::  '), isTrue);
    expect(DivSyntax.closes(' :::'), isFalse);
    expect(DivSyntax.closes('::'), isFalse);
    expect(DivSyntax.closes('::: x'), isFalse);
    expect(DivSyntax.closes(': : :'), isFalse);
  });

  test('the attributes are kept as written', () {
    expect(DivSyntax.attributesOf('::: column'), 'column');
    expect(
      DivSyntax.attributesOf('::: {.column width="40%"} :::'),
      '{.column width="40%"}',
    );
    expect(DivSyntax.attributesOf(':::'), isNull);
  });
}
