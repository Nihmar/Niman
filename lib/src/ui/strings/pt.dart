// The Portuguese (Brazil) strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class PortugueseStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  @override
  List<String> get monthNamesShort => const [
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'maio',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];
  @override
  List<String> get weekdayNames => const [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'seg.',
    'ter.',
    'qua.',
    'qui.',
    'sex.',
    'sáb.',
    'dom.',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Lixeira';
  @override
  String get trashSubtitle =>
      'Os itens excluídos vão para .trash/ (off = exclusão definitiva)';
  @override
  String get debugLogsTitle => 'Logs de depuração';
  @override
  String get debugLogsSubtitle =>
      'Registra os eventos do app em um buffer em memória';
  @override
  String get lineNumbersTitle => 'Números de linha';
  @override
  String get lineNumbersSubtitle =>
      'Mostra a coluna de números de linha no editor';
  @override
  String get keyboardOnOpenTitle => 'Teclado ao abrir';
  @override
  String get keyboardOnOpenSubtitle =>
      'Mostra o teclado assim que uma nota abre (off = no primeiro toque)';
  @override
  String get editorKindSource => 'Fonte Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get settingsPreviewEnabledTitle => 'Pré-visualização';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Mostra a nota renderizada ao lado do editor de fonte';
  @override
  String get switchToWysiwygTooltip => 'Trocar para o editor WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Trocar para a fonte Markdown';
  @override
  String get wysiwygTooLarge =>
      'Esta nota é grande demais para o editor WYSIWYG. Abra-a na fonte '
      'Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Aparência';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Biblioteca';
  @override
  String get settingsSectionReminders => 'Lembretes';
  @override
  String get settingsSectionShortcuts => 'Teclado';
  @override
  String get keyboardShortcutsTitle => 'Atalhos de teclado';
  @override
  String get settingsSectionDiagnostics => 'Diagnóstico';
  @override
  String get settingsSpellCheckTitle => 'Conferir ortografia';
  @override
  String get settingsSpellCheckSubtitle =>
      'Soblinha palavras mal escritas enquanto você escreve.';
  @override
  String get spellCheckDictionaryTitle => 'Dicionário';
  @override
  String get spellCheckDictionarySystem => 'Padrão do sistema';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Escolher dicionários';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Escolha cada idioma em que esta biblioteca está escrita. Uma '
      'palavra está certa se algum dicionário escolhido a conhece; sem '
      'escolha, o idioma do sistema decide.';
  @override
  String get spellCheckNoDictionaries =>
      'Nenhum dicionário encontrado neste sistema.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Conferir ortografia';
  @override
  String get spellCheckTitle => 'Ortografia';
  @override
  String get spellCheckEmpty => 'Sem erros de ortografia.';
  @override
  String get spellCheckUnavailable =>
      'hunspell não está instalado neste sistema.';
  @override
  String get spellCheckNoSuggestions => 'Sem sugestões';
  @override
  String spellCheckCount(int count) => '$count para revisar';
  @override
  String spellCheckLine(int line) => 'linha $line';

  @override
  String indentWidthValue(int spaces) => '$spaces espaços';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Brilho';
  @override
  String get themeBrightnessSubtitle =>
      'Claro, escuro ou o que o dispositivo estiver ajustado';
  @override
  String get themeBrightnessSystem => 'Sistema';
  @override
  String get themeBrightnessDay => 'Claro';
  @override
  String get themeBrightnessNight => 'Escuro';
  @override
  String get themePaletteTitle => 'Paleta';
  @override
  String get themePaletteSubtitle => 'As cores da interface e da nota';
  @override
  String get themePaletteSystem => 'Sistema';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Tamanho do texto da interface';
  @override
  String get uiTextScaleSubtitle =>
      'A árvore, as abas e os diálogos; por cima do ajuste do sistema';
  @override
  String get noteTextScaleTitle => 'Tamanho do texto das notas';
  @override
  String get noteTextScaleSubtitle =>
      'O editor e a pré-visualização, que sempre coincidem';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Modo de pré-visualização';
  @override
  String get previewModeSubtitle =>
      'Se a pré-visualização divide a tela com o editor ou o substitui';
  @override
  String get previewModeAuto => 'Lado a lado';
  @override
  String get previewModeSwitch => 'Tela cheia';
  @override
  String get splitRatioTitle => 'Largura da divisão';
  @override
  String get splitRatioSubtitle =>
      'A parte do editor quando a pré-visualização está lado a lado';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Formato do link';
  @override
  String get linkTypeSubtitle => 'O que o botão de link do editor insere';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get indentWidthTitle => 'Largura da indentação';
  @override
  String get indentWidthSubtitle =>
      'Espaços adicionados por nível de indentação no editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Idioma';
  @override
  String get languageSubtitle => 'O idioma dos próprios textos do app';
  @override
  String get languageSystem => 'Sistema';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Adicionar um item';
  @override
  String get listAddTooltip => 'Adicionar um item';
  @override
  String get listEmpty => 'Ainda não há itens';
  @override
  String get listDragHandleLabel => 'Reordenar o item';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Nota rápida';
  @override
  String get shortcutNewTodo => 'Nova tarefa';
  @override
  String get shortcutNewNote => 'Nova nota';
  @override
  String get shortcutNewList => 'Nova lista';
  @override
  String get shortcutToggleSidebar => 'Mostrar ou ocultar a árvore de arquivos';
  @override
  String get shortcutEditorSection => 'No editor';
  @override
  String get shortcutFind => 'Localizar';
  @override
  String get shortcutReplace => 'Localizar e substituir';
  @override
  String get shortcutSavingNote =>
      'As edições são salvas automaticamente: não há atalho para salvar.';

  // Editor status bar.
  @override
  String get outlineTooltip => 'Estrutura';
  @override
  String get outlineNoHeadings => 'Sem títulos';
  @override
  String get outlineNoTitle => '(sem título)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Negrito';
  @override
  String get toolbarItalic => 'Itálico';
  @override
  String get toolbarStrikethrough => 'Riscado';
  @override
  String get toolbarSuperscript => 'Sobrescrito';
  @override
  String get toolbarUnderline => 'Sublinhado';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Bloco de código';
  @override
  String get toolbarImage => 'Inserir imagem';
  @override
  String get toolbarHeading => 'Título';
  @override
  String get toolbarList => 'Lista';
  @override
  String get toolbarOrderedList => 'Lista numerada';
  @override
  String get toolbarQuote => 'Citação';
  @override
  String get toolbarIndent => 'Aumentar indentação';
  @override
  String get toolbarOutdent => 'Diminuir indentação';
  @override
  String get headingDialogTitle => 'Nível do título';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Barra de ferramentas do editor';
  @override
  String get toolbarSettingsHint =>
      'Arraste para reordenar; o olho mostra ou oculta um botão.';
  @override
  String get toolbarShowButton => 'Mostrar';
  @override
  String get toolbarHideButton => 'Ocultar';
  @override
  String get toolbarResetOrder => 'Restaurar os padrões';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Mostrar pré-visualização';
  @override
  String get showEditorTooltip => 'Mostrar editor';
  @override
  String get enterFullScreenTooltip => 'Tela cheia';
  @override
  String get exitFullScreenTooltip => 'Sair da tela cheia';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(tabela HTML bruta)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Procurar nas notas';
  @override
  String get searchModeWords => 'Palavras';
  @override
  String get searchModeContains => 'Contém';
  @override
  String get searchEmptyHint =>
      'Digite para procurar na biblioteca, ou chave = valor para filtrar '
      'por frontmatter';
  @override
  String get searchTooShortHint => 'Digite pelo menos 2 caracteres';
  @override
  String get searchNoMatches => 'Nenhum resultado';
  @override
  String get searchLoadMore => 'Mostrar mais';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Substituir…';
  @override
  String get replaceInNoteAction => 'Substituir nesta nota…';
  @override
  String get replaceInThisNote => 'Substituir nesta nota';
  @override
  String get replaceWithLabel => 'Substituir por';
  @override
  String get replaceCaseSensitive => 'Diferenciar maiúsculas';
  @override
  String get replaceWholeWordsHint =>
      'somente correspondências exatas de palavras inteiras são '
      'substituídas';
  @override
  String get replaceConfirm => 'Substituir';
  @override
  String get replaceCancel => 'Fechar';
  @override
  String get replaceUnavailable => 'A substituição não está disponível agora';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Localizar na nota';
  @override
  String get editorFindHint => 'Localizar';
  @override
  String get editorReplaceHint => 'Substituir';
  @override
  String get editorFindCaseTooltip => 'Diferenciar maiúsculas';
  @override
  String get editorFindPreviousTooltip => 'Correspondência anterior';
  @override
  String get editorFindNextTooltip => 'Próxima correspondência';
  @override
  String get editorFindCloseTooltip => 'Fechar a busca';
  @override
  String get editorFindReplaceModeTooltip => 'Modo substituição';
  @override
  String get editorReplaceOneTooltip => 'Substituir esta';
  @override
  String get editorReplaceAllTooltip => 'Substituir todas';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tags';
  @override
  String get tagsTitle => 'Tags';
  @override
  String get tagsEmpty =>
      'Ainda não há tags — adicione um #tag ou tags no frontmatter';
  @override
  String get tagsBackTooltip => 'Voltar à busca';
  @override
  String get tagsNotesEmpty => 'Nenhuma nota com esta tag';
  @override
  String tagsNotesCapped(int limit) =>
      'Somente as primeiras $limit estão listadas — busque a tag para '
      'restringir';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Link não encontrado';
  @override
  String get headingNotFoundTitle => 'Título não encontrado';
  @override
  String get ambiguousLinkTitle => 'Várias notas correspondem';
  @override
  String get openLinkFailed => 'Não foi possível abrir o link';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Abertas';
  @override
  String get todoDone => 'Feitas';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Todas as datas';
  @override
  String get todoFilter => 'Filtrar';
  @override
  String get todoNoTokens => 'Nenhum token nesta lista';
  @override
  String get todoCountOpen => 'abertas';
  @override
  String get todoCountDone => 'feitas';
  @override
  String get todoEmptyOpen => 'Nenhuma tarefa aberta ainda';
  @override
  String get todoEmptyDone => 'Nada concluído ainda';
  @override
  String get todoEmptyFiltered => 'Nenhuma tarefa corresponde';
  @override
  String get todoTitle => 'Tarefas';
  @override
  String get todoAddTooltip => 'Adicionar tarefa';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'O formato todo.txt';
  @override
  String get todoHelpTooltip => 'Ajuda do formato';
  @override
  String get todoHelpIntro =>
      'Suas tarefas são um único arquivo de texto plano, uma tarefa por '
      'linha. O Niman escreve a sintaxe para você, mas nada fica oculto: '
      'você pode editar o arquivo em qualquer editor e o Niman o relê.';
  @override
  String get todoHelpFilesTitle => 'Os dois arquivos';
  @override
  String get todoHelpFilesBody =>
      'As tarefas abertas estão em todo.txt na raiz da sua biblioteca. '
      'Concluí-las move a linha para done.txt, para todo.txt ficar '
      'curto. Se uma linha concluída voltar para todo.txt, o Niman a '
      'arquivará na próxima leitura dos arquivos.';
  @override
  String get todoHelpLineTitle => 'Anatomia de uma linha';
  @override
  String get todoHelpLineBody =>
      'Tudo o que vem antes da descrição é opcional e deve vir nesta '
      'ordem:';
  @override
  String get todoHelpDoneBody =>
      'Marca a tarefa como feita. O Niman a adiciona quando você marca a '
      'caixinha.';
  @override
  String get todoHelpPriority => 'de (A) a (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Prioridade. A é a mais alta. Aparece como selo na lista.';
  @override
  String get todoHelpDatesBody =>
      'Data de conclusão e depois data de criação. Com uma única data, é '
      'a de criação, a menos que a linha comece com x.';
  @override
  String get todoHelpTokensTitle => 'Projetos, contextos e tags';
  @override
  String get todoHelpTokensBody =>
      'Em qualquer ponto da descrição, uma palavra com um destes '
      'prefixos vira um chip pelo qual você pode filtrar. Nada é '
      'predefinido: um token existe assim que você o escreve.';
  @override
  String get todoHelpProjectBody =>
      'Do que a tarefa faz parte, por exemplo +cozinha ou +tese.';
  @override
  String get todoHelpContextBody =>
      'Onde ou como você vai fazer, por exemplo @casa ou @chamadas.';
  @override
  String get todoHelpHashtagBody =>
      'Uma etiqueta livre, para tudo o que os outros dois não cobrem.';
  @override
  String get todoHelpTagsTitle => 'Datas e lembretes';
  @override
  String get todoHelpTagsBody =>
      'São tags chave:valor. O Niman as escreve a partir da janela da '
      'tarefa e as lê onde quer que apareçam na linha.';
  @override
  String get todoHelpDueBody =>
      'O prazo. Dirige o selo colorido e os filtros por data.';
  @override
  String get todoHelpRemBody =>
      'Quando enviar uma notificação, no seu fuso horário. Dispara com '
      'a tela desligada e o app fechado.';
  @override
  String get todoHelpRemDesktop =>
      'No desktop o Niman precisa estar aberto quando a hora chega: o '
      'lembrete é exibido enquanto o app está aberto, e nada dispara com '
      'ele fechado.';
  @override
  String get todoHelpOtherBody =>
      'Conservadas exatamente como escritas, para que tags de outros '
      'apps todo.txt sobrevivam à ida e volta. O Niman não age sobre '
      'elas, rec: incluída: uma tarefa recorrente ainda não se repete.';
  @override
  String get todoHelpEditTitle => 'Edição fora do Niman';
  @override
  String get todoHelpEditBody =>
      'Uma tarefa que você não tocou é reescrita byte a byte, espaçamentos '
      'estranhos incluídos. Edite uma linha e o Niman reescreve só '
      'aquela na forma canônica, deixando o resto do arquivo como está.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Adicionar tarefa';
  @override
  String get todoEditTitle => 'Editar tarefa';
  @override
  String get todoDescriptionHint => 'Descrição';
  @override
  String get todoCancel => 'Cancelar';
  @override
  String get todoSave => 'Salvar';
  @override
  String get todoEditAction => 'Editar';
  @override
  String get todoDeleteAction => 'Excluir';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Atrasadas';
  @override
  String get todoDueToday => 'Hoje';
  @override
  String get todoDueNext7 => 'Próximos 7 dias';
  @override
  String get todoDueNoDate => 'Sem data';
  @override
  String get todoRowDue => 'Vence';
  @override
  String get todoRowDueToday => 'Vence hoje';
  @override
  String get todoSortTooltip => 'Ordenar';
  @override
  String get todoSortDue => 'Data de vencimento';
  @override
  String get todoSortPriority => 'Prioridade';
  @override
  String get todoSortCreation => 'Data de criação';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Sem prioridade';
  @override
  String get todoNoPriorityShort => 'Nenhuma';
  @override
  String get todoMorePriorities => 'Mais…';
  @override
  String get todoPriorityTitle => 'Prioridade';
  @override
  String get todoNoDueDate => 'Sem data de vencimento';
  @override
  String get todoNoReminder => 'Sem lembrete';
  @override
  String get todoAddProject => '+ Projeto';
  @override
  String get todoAddContext => '@ Contexto';
  @override
  String get todoAddHashtag => '# Tag';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Lembretes de tarefas';
  @override
  String get todoReminderChannelDescription =>
      'Alertas agendados para tarefas com horário de lembrete.';
  @override
  String get todoReminderBody => 'Lembrete de tarefa';
  @override
  String get todoReminderFallbackTitle => 'Lembrete de tarefa';
  @override
  String get todoReminderBlocked =>
      'As notificações estão desligadas, então os lembretes não aparecerão.';
  @override
  String get todoReminderBattery =>
      'A otimização de bateria está ativa para o Niman. O sistema pode '
      'colocar o app em suspensão e perder lembretes pendentes.';
  @override
  String get todoReminderInexact =>
      'Este dispositivo não permite alarmes exatos, então um lembrete '
      'pode chegar com alguns minutos de atraso com a tela desligada.';
  @override
  String get reminderShowTokensTitle => 'Tags nas notificações de lembrete';
  @override
  String get reminderShowTokensSubtitle =>
      'Mantém +projeto, @contexto e #tag no texto da notificação. Off '
      'mostra só a tarefa que você digitou.';
  @override
  String get todoReminderFixAction => 'Abrir configurações';
  @override
  String get todoReminderDismissAction => 'Dispensar';
  @override
  String get todoReminderDue => 'Vence';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Cancelar';
  @override
  String get actionCreate => 'Criar';
  @override
  String get actionNew => 'Novo';
  @override
  String get actionSave => 'Salvar';
  @override
  String get actionClear => 'Esvaziar';
  @override
  String get actionChoose => 'Escolher';
  @override
  String get actionDelete => 'Excluir';
  @override
  String get actionRename => 'Renomear';
  @override
  String get actionMove => 'Mover';
  @override
  String get saveAndClose => 'Salvar e fechar';
  @override
  String get closeUnsavedTitle => 'Alterações não salvas';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” tem alterações que ainda não foram '
          'salvas. Salvar antes de fechar?';
    }
    return '$names.length notas têm alterações que ainda não foram '
        'salvas. Salvar antes de fechar?';
  }

  @override
  String get closeSaveFailed =>
      'Não foi possível salvar; a nota continua aberta.';
  @override
  String get actionRestore => 'Restaurar';
  @override
  String get actionEmpty => 'Esvaziar';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Ocultar o painel (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Mostrar o painel (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimizar';
  @override
  String get windowMaximizeTooltip => 'Maximizar';
  @override
  String get windowRestoreTooltip => 'Restaurar';
  @override
  String get windowCloseTooltip => 'Fechar';
  @override
  String get tabFiles => 'Arquivos';
  @override
  String get tabSearch => 'Procurar';
  @override
  String get tabSettings => 'Configurações';
  @override
  String get quickNoteTitle => 'Nota rápida';
  @override
  String get treeEmpty => 'Ainda não há notas';
  @override
  String get selectANote => 'Selecione uma nota';
  @override
  String get showListTooltip => 'Mostrar lista';
  @override
  String get editRawTooltip => 'Editar a fonte';
  @override
  String get sortAscTooltip => 'Ordenar A-Z';
  @override
  String get sortDescTooltip => 'Ordenar Z-A';
  @override
  String get newNoteTitle => 'Nova nota';
  @override
  String get newFolderTitle => 'Nova pasta';
  @override
  String get newNoteHere => 'Nova nota aqui';
  @override
  String get newFolderHere => 'Nova pasta aqui';
  @override
  String get newListNoteTitle => 'Nova nota-lista';
  @override
  String get newListNoteDefault => 'Minha lista';
  @override
  String get setAsQuickNote => 'Definir como nota rápida';
  @override
  String get currentQuickNote => 'Nota rápida atual';
  @override
  String get pinnedSection => 'Fixadas';
  @override
  String pinnedSectionCount(int count) => 'Fixadas · $count';
  @override
  String get templateFolderTitle => 'Pasta de modelos';
  @override
  String get newFromTemplateTitle => 'Nova a partir de modelo';
  @override
  String get newFromTemplateHere => 'Nova a partir de modelo aqui';
  @override
  String get templateFormTitle => 'Preencher o modelo';
  @override
  String get templateFormBacklink => 'Vinculada de';
  @override
  String get templateFormNoNote => 'Sem nota';
  @override
  String get templateFormPickNote => 'Escolher a nota';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Locais reservados dos modelos';
  @override
  String get templateHelpIntro =>
      'Um modelo é uma nota comum com buracos. Criar uma nota a partir de '
      'um copia seu texto e preenche os buracos.';
  @override
  String get templateHelpUnknown =>
      'Um local reservado que o Niman não conhece fica exatamente como '
      'escrito, para que um erro de digitação apareça na nota em vez de '
      'engolir uma linha em silêncio.';
  @override
  String get templateHelpValuesTitle => 'Valores';
  @override
  String get templateHelpTitleBody =>
      'O nome com o qual a nota vai ser criada.';
  @override
  String get templateHelpDateBody =>
      'Hoje, e a hora agora. Os dois aceitam um formato: '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'A data e a hora juntas.';
  @override
  String get templateHelpUuidBody =>
      'Um identificador novo, diferente em cada ocorrência.';
  @override
  String get templateHelpCounterBody =>
      'Um número que conta por nome, guardado entre reinícios: a primeira '
      'nota escreve 1, a próxima 2. O mesmo nome em uma nota escreve o '
      'mesmo número; combine com |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Coloca o cursor aqui quando a nota é criada; o marcador não é '
      'escrito. O primeiro marcador vence, sem filtros, só notas novas — '
      'e o teclado abre mesmo com o auto-foco desligado.';
  @override
  String get templateHelpDatesTitle => 'Escrever uma data';
  @override
  String get templateHelpDatesBody =>
      'Estes representam partes da data dentro de um formato. O resto '
      'é literal, e também o texto entre aspas simples. Os nomes de mês '
      'e de dia seguem o idioma do app.';
  @override
  String get templateHelpYear => 'o ano: 2026, 26';
  @override
  String get templateHelpMonth => 'o mês: 03, 3, março, mar.';
  @override
  String get templateHelpDay => 'o dia: 09, 9, segunda-feira, seg.';
  @override
  String get templateHelpTime => 'horas, minutos, segundos';
  @override
  String get templateHelpWeek => 'a semana ISO e o trimestre: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtros';
  @override
  String get templateHelpFiltersBody =>
      'Um valor pode ser seguido de filtros, aplicados da esquerda para a '
      'direita.';
  @override
  String get templateHelpCaseBody =>
      'Maiúsculas, minúsculas, e a primeira letra de cada palavra — uma '
      'palavra que você capitalizou fica como está.';
  @override
  String get templateHelpSlugBody =>
      'A forma de link do texto, para construir um wikilink.';
  @override
  String get templateHelpPadBody =>
      'Remove os espaços nas pontas; preenche com zeros até uma largura; '
      'usa um valor de recuo quando o valor está vazio.';
  @override
  String get templateHelpShiftBody =>
      'Move uma data de dias, semanas, meses ou anos — a aula da semana '
      'que vem, o arquivo do mês passado.';
  @override
  String get templateHelpSnapBody =>
      'Alinha uma data ao início ou ao fim da sua semana, mês ou ano.';
  @override
  String get templateHelpAskTitle => 'Peguntando algo a você';
  @override
  String get templateHelpAskBody =>
      'Um formulário aparece antes da nota ser criada, uma caixa por '
      'pergunta — e uma para o link de volta, quando o modelo quer. A '
      'mesma etiqueta duas vezes é uma pergunta só, e a resposta '
      'preenche cada ocorrência — a pasta e o nome do arquivo '
      'incluídos.';
  @override
  String get templateHelpAskFieldBody =>
      'Uma caixa para digitar; o texto depois dos dois dois-pontos é '
      'com ele que ela começa.';
  @override
  String get templateHelpChoiceBody =>
      'Uma escolha de uma lista, separada por vírgulas.';
  @override
  String get templateHelpWhereTitle => 'Onde a nota vai';
  @override
  String get templateHelpWhereBody =>
      'Estes não são texto: são instruções, e vivem em um bloco niman: do '
      'frontmatter do próprio modelo. O bloco é executado e depois '
      'removido, então nunca aparece na nota. Seus valores podem conter '
      'locais reservados.';
  @override
  String get templateHelpFolderBody =>
      'A pasta em que a nota é criada, criada se não existir. Sem ela, a '
      'nota chega onde você estava.';
  @override
  String get templateHelpFilenameBody =>
      'O nome da nota. Um modelo que declara isso não é perguntado o '
      'nome.';
  @override
  String get templateHelpAppendBody =>
      'Adiciona à nota se ela já existe, em vez de criar uma segunda. É '
      'isso que transforma um mês de reuniões em um único arquivo.';
  @override
  String get templateHelpOpenBody =>
      'O que acontece quando a nota existe: o editor (o padrão), a '
      'pré-visualização, ou nada — a nota é arquivada e você fica onde '
      'estava.';
  @override
  String get templateHelpAroundTitle => 'Onde ela veio';
  @override
  String get templateHelpParentBody =>
      'Uma nota que você escolhe no formulário, que sugere a que está na '
      'tela; escreva [[{{parent}}]] para um link de volta.';
  @override
  String get templateHelpFolderValueBody => 'A pasta em que a nota terminou.';
  @override
  String get templateHelpClipboardBody =>
      'O que está na área de transferência, e a seleção do editor quando '
      'a nota partiu de uma.';
  @override
  String get templateHelpIncludeTitle => 'Reutilizar um pedaço';
  @override
  String get templateHelpIncludeBody =>
      'Cola outro modelo, para que dez modelos compartilhem uma única '
      'checklist. É procurado primeiro na pasta de modelos, e o .md '
      'pode ser omitido. Suas próprias perguntas entram no mesmo '
      'formulário.';
  @override
  String get templateHelpExampleTitle => 'Tudo junto';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ nenhum modelo “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” inclui a si mesmo';
  @override
  String includeTooDeep(String path) => '⚠ “$path” está aninhado demais';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter não lido: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'O frontmatter de “$template” não foi lido, então sua pasta e seu '
      'nome de arquivo não fizeram nada: $reason';
  @override
  String get templatePickerTitle => 'Escolher um modelo';
  @override
  String templatePickerEmpty(String folder) =>
      'Ainda não há modelos. Coloque uma nota em $folder/ e ela vira um.';

  // Tree actions.
  @override
  String get actionPin => 'Fixar';
  @override
  String get actionUnpin => 'Não fixar mais';
  @override
  String get movedToTrash => 'Movido para a lixeira';
  @override
  String get deletedMessage => 'Excluído';
  @override
  String deleteToTrashConfirm(String name) => '$name será movido para .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name será excluído permanentemente';
  @override
  String get chooseDestination => 'Escolher o destino';
  @override
  String get libraryRoot => 'Raiz da biblioteca';
  @override
  String moveTitle(String name) => 'Mover $name';
  @override
  String headingLevelLabel(int level) => 'Título nível $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Ainda não há nota rápida. Escolha uma existente ou crie uma nova — '
      'a nota rápida abre aqui.';
  @override
  String get quickNoteChooseAction => 'Escolher uma nota…';
  @override
  String get quickNoteCreateAction => 'Criar uma nota nova…';
  @override
  String get quickNoteNewTitle => 'Nova nota rápida';
  @override
  String get quickNotePickerTitle => 'Escolher a nota rápida';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nova pasta';
  @override
  String get folderPickerEmpty => 'Ainda não há pastas';
  @override
  String get listFolderTitle => 'Pasta de listas';

  // Trash (M1).
  @override
  String get trashEmpty => 'A lixeira está vazia';
  @override
  String get trashEmptyAction => 'Esvaziar a lixeira';
  @override
  String get trashEmptyConfirm =>
      'Isso exclui permanentemente tudo o que está na pasta de lixeira, '
      'incluindo itens que o Niman não colocou lá.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name será excluído permanentemente (sem restauração)';
  @override
  String get trashDeletePermanently => 'Excluir permanentemente';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Abra uma pasta de notas Markdown como sua biblioteca';
  @override
  String get openLibraryExisting => 'Abrir existente';
  @override
  String get openLibraryCreate => 'Criar nova';
  @override
  String get openLibraryCreateTitle => 'Criar uma biblioteca nova';
  @override
  String get openLibraryFolderName => 'Nome da pasta';
  @override
  String get openLibraryChooseFolder => 'Escolha a pasta da biblioteca';
  @override
  String get openLibraryChooseParent =>
      'Escolha a pasta em que a biblioteca será criada';
  @override
  String get openLibraryUnsupported =>
      'Essa pasta não é suportada. Escolha uma pasta no armazenamento do '
      'dispositivo.';
  @override
  String indexingCount(int done, int total) => '$done de $total notas';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Suas bibliotecas';
  @override
  String get libraryUnreachable => 'Inacessível';
  @override
  String get libraryOpenedToday => 'Aberta hoje';
  @override
  String get libraryOpenedYesterday => 'Aberta ontem';
  @override
  String libraryOpenedDaysAgo(int days) => 'Aberta há $days dias';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Aberta em $d/$m/${when.year}';
  }

  @override
  String get libraryOpenNow => 'Abrir agora';
  @override
  String get switchLibraryTitle => 'Trocar de biblioteca';
  @override
  String get libraryForget => 'Esquecer';
  @override
  String libraryForgetTitle(String name) => 'Esquecer “$name”?';
  @override
  String get libraryForgetExplained =>
      'Ela sai desta lista. A pasta, as notas e as configurações da '
      'biblioteca ficam onde estão, e reabrindo ela volta.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Conceder acesso aos arquivos';
  @override
  String get storageAccessNeeded =>
      'Sem o “acesso a todos os arquivos”, o Niman não consegue ler suas '
      'notas. Conceda-o para abrir uma biblioteca.';
  @override
  String get storageAccessExplained =>
      'O Niman lê suas notas como arquivos comuns, então o Android '
      'precisa permitir o acesso a todos os arquivos. Nada é enviado, e '
      'só a pasta da biblioteca que você escolher é lida.';
  @override
  String folderAccessDenied(Object error) =>
      'O sistema não deu acesso à pasta: $error';
  @override
  String folderPickFailed(Object error) =>
      'Não foi possível escolher a pasta: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Configurações';
  @override
  String get libraryPathTitle => 'Caminho da biblioteca';
  @override
  String get reindexTitle => 'Reindexar agora';
  @override
  String get reindexDone => 'Reindexação concluída';
  @override
  String get closeLibraryTitle => 'Fechar a biblioteca';
  @override
  String get exportLogTitle => 'Exportar o log de depuração';
  @override
  String get exportLogSubtitle =>
      'Salva os eventos registrados em um arquivo à sua escolha';
  @override
  String get exportLogEmpty => 'O buffer do log de depuração está vazio';
  @override
  String get quickNoteUnset => 'Ainda não definida';
  @override
  String exportLogDone(Object target) =>
      'Log de depuração exportado para $target';
  @override
  String exportLogFailed(Object error) => 'Falha na exportação: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Nenhuma palavra inteira “$term” foi encontrada';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '$occurrences ocorrência(s) de “$term” substituída(s) em $notes '
      'nota(s)';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped nota(s) aberta(s) ignorada(s))';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Nenhuma palavra inteira exata “$term” '
      '${only == null ? 'encontrada' : 'encontrada em $only'}';
}
