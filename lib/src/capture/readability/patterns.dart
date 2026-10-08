/// Readability's patterns and lists: what a class or an id says about an
/// element, which tags are phrasing content, which attributes are only
/// presentation.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0. The names are upstream's, so a diff against a new release
/// reads line by line.
library;

/// Readability.js's `REGEXPS`.
abstract final class ReadabilityPatterns {
  // NOTE: These two regular expressions are duplicated in readerable.dart,
  // as upstream duplicates them in Readability-readerable.js.

  /// A class or an id that is probably not the article.
  static final unlikelyCandidates = RegExp(
    '-ad-|ai2html|banner|breadcrumbs|combx|comment|community|cover-wrap|'
    'disqus|extra|footer|gdpr|header|legends|menu|related|remark|replies|'
    'rss|shoutbox|sidebar|skyscraper|social|sponsor|supplemental|ad-break|'
    'agegate|pagination|pager|popup|yom-remote',
    caseSensitive: false,
  );

  /// …unless it says this too.
  static final okMaybeItsACandidate = RegExp(
    'and|article|body|column|content|main|shadow',
    caseSensitive: false,
  );

  /// A class or an id that adds to an element's score.
  static final positive = RegExp(
    'article|body|content|entry|hentry|h-entry|main|page|pagination|post|'
    'text|blog|story',
    caseSensitive: false,
  );

  /// A class or an id that takes from it.
  static final negative = RegExp(
    r'-ad-|hidden|^hid$| hid$| hid |^hid |banner|combx|comment|com-|'
    'contact|footer|gdpr|masthead|media|meta|outbrain|promo|related|scroll|'
    'share|shoutbox|sidebar|skyscraper|sponsor|shopping|tags|widget',
    caseSensitive: false,
  );

  /// A class or an id that names the byline.
  static final byline = RegExp(
    'byline|author|dateline|writtenby|p-author',
    caseSensitive: false,
  );

  /// Two or more white spaces.
  static final normalize = RegExp(r'\s{2,}');

  /// The video hosts whose embeds stay.
  static final videos = RegExp(
    r'\/\/(www\.)?((dailymotion|youtube|youtube-nocookie|player\.vimeo|'
    r'v\.qq)\.com|(archive|upload\.wikimedia)\.org|player\.twitch\.tv)',
    caseSensitive: false,
  );

  /// A class or an id that names sharing buttons.
  static final shareElements = RegExp(
    r'(\b|_)(share|sharedaddy)(\b|_)',
    caseSensitive: false,
  );

  /// What words are split on.
  static final tokenize = RegExp(r'\W+');

  /// Only white space.
  static final whitespace = RegExp(r'^\s*$');

  /// Ends in something other than white space.
  static final hasContent = RegExp(r'\S$');

  /// A link to a place in the same page.
  static final hashUrl = RegExp('^#.+');

  /// One URL of a `srcset`, its descriptor and its separator.
  static final srcsetUrl = RegExp(r'(\S+)(\s+[\d.]+[xw])?(\s*(?:,|$))');

  /// A base64 `data:` URL, its media type captured.
  static final b64DataUrl = RegExp(
    r'^data:\s*([^\s;,]+)\s*;\s*base64\s*,',
    caseSensitive: false,
  );

  /// Commas as used in Latin, Sindhi, Chinese and various other scripts.
  static final commas = RegExp(',|،|﹐|︐|︑|⹁|⸴|⸲|，');

  /// The schema.org types of an article (https://schema.org/Article).
  static final jsonLdArticleTypes = RegExp(
    '^Article|AdvertiserContentArticle|NewsArticle|AnalysisNewsArticle|'
    'AskPublicNewsArticle|BackgroundNewsArticle|OpinionNewsArticle|'
    'ReportageNewsArticle|ReviewNewsArticle|Report|SatiricalArticle|'
    'ScholarlyArticle|MedicalScholarlyArticle|SocialMediaPosting|'
    'BlogPosting|LiveBlogPosting|DiscussionForumPosting|TechArticle|'
    r'APIReference$',
  );

  /// The whole text of an advertisement's block.
  static final adWords = RegExp(
    '^(ad(vertising|vertisement)?|pub(licité)?|werb(ung)?|广告|Реклама|'
    r'Anuncio)$',
    caseSensitive: false,
    unicode: true,
  );

  /// The whole text of a loading indicator.
  static final loadingWords = RegExp(
    r'^((loading|正在加载|Загрузка|chargement|cargando)(…|\.\.\.)?)$',
    caseSensitive: false,
    unicode: true,
  );

  /// A picture's file name in an attribute.
  static final imageExtension = RegExp(
    r'\.(jpg|jpeg|png|webp)',
    caseSensitive: false,
  );
}

/// Roles that are not the article.
const List<String> unlikelyRoles = [
  'menu',
  'menubar',
  'complementary',
  'navigation',
  'alert',
  'alertdialog',
  'dialog',
];

/// The tags that keep a `div` from becoming a `p`.
const Set<String> divToPElems = {
  'BLOCKQUOTE',
  'DL',
  'DIV',
  'IMG',
  'OL',
  'P',
  'PRE',
  'TABLE',
  'UL',
};

/// The siblings of the top candidate that are not turned into `div`s.
const List<String> alterToDivExceptions = [
  'DIV',
  'ARTICLE',
  'SECTION',
  'P',
  'OL',
  'UL',
];

/// Attributes that only say how something looks.
const List<String> presentationalAttributes = [
  'align',
  'background',
  'bgcolor',
  'border',
  'cellpadding',
  'cellspacing',
  'frame',
  'hspace',
  'rules',
  'style',
  'valign',
  'vspace',
];

/// The elements whose `width` and `height` are presentation too.
const List<String> deprecatedSizeAttributeElems = [
  'TABLE',
  'TH',
  'TD',
  'HR',
  'PRE',
];

/// Phrasing content. Canvas, iframe, svg and video qualify too, but tend to
/// be removed when put into paragraphs, so upstream leaves them out.
const List<String> phrasingElems = [
  'ABBR',
  'AUDIO',
  'B',
  'BDO',
  'BR',
  'BUTTON',
  'CITE',
  'CODE',
  'DATA',
  'DATALIST',
  'DFN',
  'EM',
  'EMBED',
  'I',
  'IMG',
  'INPUT',
  'KBD',
  'LABEL',
  'MARK',
  'MATH',
  'METER',
  'NOSCRIPT',
  'OBJECT',
  'OUTPUT',
  'PROGRESS',
  'Q',
  'RUBY',
  'SAMP',
  'SCRIPT',
  'SELECT',
  'SMALL',
  'SPAN',
  'STRONG',
  'SUB',
  'SUP',
  'TEXTAREA',
  'TIME',
  'VAR',
  'WBR',
];

/// The tags scored as paragraphs.
const List<String> defaultTagsToScore = [
  'SECTION',
  'H2',
  'H3',
  'H4',
  'H5',
  'H6',
  'P',
  'TD',
  'PRE',
];

/// The classes Readability sets itself.
const List<String> defaultClassesToPreserve = ['page'];
