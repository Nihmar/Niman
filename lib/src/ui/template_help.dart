/// Every template placeholder, explained in the app (T-TPL-08).
///
/// Templates are notes the user writes by hand, in any editor, and the
/// placeholders are the only part of a note that is not what it looks
/// like. There is nowhere else to find out what may go in one, so the
/// list lives next to the template-folder setting, where somebody
/// setting templates up is already standing.
///
/// It documents what this build actually substitutes. A placeholder that
/// is not on this page is one Niman leaves standing.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/help_layout.dart';
import 'package:niman/src/ui/strings.dart';

/// A read-only reference for the template placeholders.
final class TemplateHelpScreen extends StatelessWidget {
  /// Creates the help screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.templateHelpTitle)),
      body: ListView(
        key: const Key('template-help'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          HelpParagraph(AppStrings.templateHelpIntro),
          const HelpExample('# {{title}}\n\nWritten {{date}} at {{time}}.'),
          HelpParagraph(AppStrings.templateHelpUnknown),

          HelpSection(AppStrings.templateHelpValuesTitle),
          HelpRow('{{title}}', AppStrings.templateHelpTitleBody),
          HelpRow('{{date}}  {{time}}', AppStrings.templateHelpDateBody),
          HelpRow('{{now}}', AppStrings.templateHelpNowBody),
          HelpRow('{{uuid}}', AppStrings.templateHelpUuidBody),
          HelpRow('{{counter:name}}', AppStrings.templateHelpCounterBody),
          HelpRow('{{cursor}}', AppStrings.templateHelpCursorBody),

          HelpSection(AppStrings.templateHelpDatesTitle),
          HelpParagraph(AppStrings.templateHelpDatesBody),
          HelpRow('YYYY  YY', AppStrings.templateHelpYear),
          HelpRow('MM  M  MMMM  MMM', AppStrings.templateHelpMonth),
          HelpRow('DD  D  dddd  ddd', AppStrings.templateHelpDay),
          HelpRow('HH  H  mm  m  ss  s', AppStrings.templateHelpTime),
          HelpRow('WW  W  Q', AppStrings.templateHelpWeek),
          const HelpExample("{{date:dddd D MMMM YYYY}}   {{date:'week' WW}}"),

          HelpSection(AppStrings.templateHelpFiltersTitle),
          HelpParagraph(AppStrings.templateHelpFiltersBody),
          HelpRow('|upper  |lower  |title', AppStrings.templateHelpCaseBody),
          HelpRow('|slug', AppStrings.templateHelpSlugBody),
          HelpRow(
            '|trim  |pad:3  |default:text',
            AppStrings.templateHelpPadBody,
          ),
          HelpRow('|+7d  |-1w  |+1m  |+1y', AppStrings.templateHelpShiftBody),
          HelpRow(
            '|startof:week  |endof:month',
            AppStrings.templateHelpSnapBody,
          ),
          const HelpExample('{{date:YYYY-MM-DD|+7d}}   {{title|slug}}'),

          HelpSection(AppStrings.templateHelpAskTitle),
          HelpParagraph(AppStrings.templateHelpAskBody),
          HelpRow(
            '{{ask:Label}}  {{ask:Label:start}}',
            AppStrings.templateHelpAskFieldBody,
          ),
          HelpRow(
            '{{choice:Label:one,two,three}}',
            AppStrings.templateHelpChoiceBody,
          ),

          HelpSection(AppStrings.templateHelpWhereTitle),
          HelpParagraph(AppStrings.templateHelpWhereBody),
          HelpRow('folder:', AppStrings.templateHelpFolderBody),
          HelpRow('filename:', AppStrings.templateHelpFilenameBody),
          HelpRow('append: true', AppStrings.templateHelpAppendBody),
          HelpRow(
            'open: editor | preview | none',
            AppStrings.templateHelpOpenBody,
          ),
          const HelpExample(
            '---\n'
            'niman:\n'
            '  folder: Journal/{{date:YYYY}}\n'
            '  filename: "{{date:YYYY-MM-DD}}"\n'
            '  append: true\n'
            '---',
          ),

          HelpSection(AppStrings.templateHelpAroundTitle),
          HelpRow('{{parent}}', AppStrings.templateHelpParentBody),
          HelpRow('{{folder}}', AppStrings.templateHelpFolderValueBody),
          HelpRow(
            '{{clipboard}}  {{selection}}',
            AppStrings.templateHelpClipboardBody,
          ),

          HelpSection(AppStrings.templateHelpIncludeTitle),
          HelpRow('{{include:_header}}', AppStrings.templateHelpIncludeBody),

          HelpSection(AppStrings.templateHelpExampleTitle),
          const HelpExample(
            '---\n'
            'niman:\n'
            '  folder: World/{{choice:Kind:Characters,Places}}\n'
            '  filename: "{{ask:Name}}"\n'
            'type: character\n'
            'tags: [world]\n'
            '---\n'
            '\n'
            '# {{ask:Name}}\n'
            '\n'
            '**Faction:** {{choice:Faction:Crown,Rebels,Neutral}}\n'
            '**First seen in:** [[{{parent}}]]\n'
            '**Created:** {{date:dddd D MMMM YYYY}}\n'
            '\n'
            '{{include:_world-footer}}',
          ),
        ],
      ),
    );
  }
}
