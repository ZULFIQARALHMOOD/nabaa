// نبع — محرر نصوص عربي سريع ونظيف.
//
// واجهة واحدة: شريط أدوات علوي (تراجع/إعادة، غامق، مائل، تسطير، لون، صورة)،
// ورقة كتابة بيضاء تشبه A4، وشريط حالة بعدد الكلمات والأحرف.
// اللغة والاتجاه افتراضيًا: العربية ومن اليمين إلى اليسار (RTL).
//
// المحرر مبني على flutter_quill، وإدراج الصور عبر flutter_quill_extensions.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const NabaaApp());
}

// ───────────────────────────── الألوان والثيم ─────────────────────────────

const Color _paperColor = Color(0xFFFFFFFF);
const Color _deskColor = Color(0xFFECEFF1);
const Color _inkColor = Color(0xFF1F2933);
const Color _hairline = Color(0xFFE3E7EA);
const Color _seedColor = Color(0xFF0E7490);

/// ألوان النص المعروضة في لوحة الألوان.
const List<Color> _palette = <Color>[
  Color(0xFF1F2933),
  Color(0xFF64748B),
  Color(0xFF0E7490),
  Color(0xFF0F766E),
  Color(0xFF16A34A),
  Color(0xFFCA8A04),
  Color(0xFFDC2626),
  Color(0xFFDB2777),
  Color(0xFF7C3AED),
  Color(0xFF2563EB),
];

/// يحوّل لونًا إلى صيغة flutter_quill: `#RRGGBB`.
String _hexOf(Color color) {
  final String hex = (color.toARGB32() & 0xFFFFFF)
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();
  return '#$hex';
}

// ───────────────────────────── التطبيق ─────────────────────────────

class NabaaApp extends StatelessWidget {
  const NabaaApp({super.key});

  static final ThemeData _theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    scaffoldBackgroundColor: _deskColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: _paperColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: _inkColor),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نبع',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // الاتجاه من اليمين إلى اليسار افتراضيًا حتى لو غيّر النظام اللغة.
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const NabaaEditorPage(),
    );
  }
}

// ───────────────────────────── شاشة المحرر ─────────────────────────────

class NabaaEditorPage extends StatefulWidget {
  const NabaaEditorPage({super.key});

  @override
  State<NabaaEditorPage> createState() => _NabaaEditorPageState();
}

class _NabaaEditorPageState extends State<NabaaEditorPage> {
  final QuillController _controller = QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// تنسيق النص الأساسي: خط 16، تباعد أسطر مريح للعربية، وفجوة بين الفقرات.
  static const DefaultStyles _editorStyles = DefaultStyles(
    paragraph: DefaultTextBlockStyle(
      TextStyle(color: _inkColor, fontSize: 16, height: 1.9),
      HorizontalSpacing(0, 0),
      VerticalSpacing(0, 10),
      VerticalSpacing(0, 0),
      null,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _deskColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.water_drop_rounded, size: 22, color: scheme.primary),
            const SizedBox(width: 8),
            const Text(
              'نبع',
              style: TextStyle(
                color: _inkColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _hairline),
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildToolbar(scheme),
          Expanded(child: _buildPaper()),
          _buildStatusBar(scheme),
        ],
      ),
    );
  }

  // ───────────────────────────── شريط الأدوات ─────────────────────────────

  Widget _buildToolbar(ColorScheme scheme) {
    return Container(
      color: _paperColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) {
          final Style style = _controller.getSelectionStyle();
          final Color? color = _currentTextColor();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _ToolButton(
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: 'تراجع',
                  onPressed: _controller.hasUndo ? _controller.undo : null,
                ),
                _ToolButton(
                  icon: const Icon(Icons.redo_rounded),
                  tooltip: 'إعادة',
                  onPressed: _controller.hasRedo ? _controller.redo : null,
                ),
                _toolbarDivider(),
                _ToolButton(
                  icon: const Icon(Icons.format_bold_rounded),
                  tooltip: 'غامق',
                  active: style.containsKey(Attribute.bold.key),
                  onPressed: () => _toggleAttribute(Attribute.bold),
                ),
                _ToolButton(
                  icon: const Icon(Icons.format_italic_rounded),
                  tooltip: 'مائل',
                  active: style.containsKey(Attribute.italic.key),
                  onPressed: () => _toggleAttribute(Attribute.italic),
                ),
                _ToolButton(
                  icon: const Icon(Icons.format_underline_rounded),
                  tooltip: 'تسطير',
                  active: style.containsKey(Attribute.underline.key),
                  onPressed: () => _toggleAttribute(Attribute.underline),
                ),
                _toolbarDivider(),
                _ToolButton(
                  icon: _colorIcon(color),
                  tooltip: 'لون النص',
                  active: color != null,
                  onPressed: _pickTextColor,
                ),
                _toolbarDivider(),
                _ToolButton(
                  icon: const Icon(Icons.image_outlined),
                  tooltip: 'إضافة صورة',
                  onPressed: _insertImage,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: _hairline,
    );
  }

  /// أيقونة زر اللون مع شريط صغير يوضّح اللون الحالي.
  Widget _colorIcon(Color? color) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        const Icon(Icons.format_color_text_rounded),
        Positioned(
          bottom: 4,
          child: Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: color ?? const Color(0xFF9AA5B1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────── ورقة الكتابة ─────────────────────────────

  Widget _buildPaper() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double pageWidth = math.min(constraints.maxWidth - 24.0, 820.0);
        final double pageHeight = math.max(constraints.maxHeight - 16.0, 240.0);
        return Center(
          child: SizedBox(
            width: pageWidth,
            height: pageHeight,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _paperColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: QuillEditorConfig(
                  scrollable: true,
                  padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
                  placeholder: 'ابدأ الكتابة هنا…',
                  customStyles: _editorStyles,
                  embedBuilders: <EmbedBuilder>[
                    QuillEditorImageEmbedBuilder(
                      config: const QuillEditorImageEmbedConfig(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────── شريط الحالة ─────────────────────────────

  Widget _buildStatusBar(ColorScheme scheme) {
    return Container(
      color: _paperColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (BuildContext context, Widget? child) {
              return Row(
                children: <Widget>[
                  Icon(Icons.notes_rounded, size: 16, color: scheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    'الكلمات: ${_wordCount}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.text_fields_rounded,
                    size: 16,
                    color: scheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'الأحرف: ${_characterCount}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: scheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'محلي',
                    style: TextStyle(color: scheme.outline, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── التنسيق ─────────────────────────────

  void _toggleAttribute(Attribute<dynamic> attribute) {
    final bool isActive = _controller.getSelectionStyle().containsKey(
      attribute.key,
    );
    _controller.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
    _focusNode.requestFocus();
  }

  Color? _currentTextColor() {
    final Attribute<dynamic>? attribute = _controller
        .getSelectionStyle()
        .attributes[Attribute.color.key];
    final Object? value = attribute?.value;
    if (value is! String || value.isEmpty) {
      return null;
    }
    final String hex = value.replaceFirst('#', '');
    final String normalized = switch (hex.length) {
      6 => 'FF$hex',
      8 => hex,
      _ => '',
    };
    if (normalized.isEmpty) {
      return null;
    }
    final int? argb = int.tryParse(normalized, radix: 16);
    return argb == null ? null : Color(argb);
  }

  Future<void> _pickTextColor() async {
    final _ColorChoice? choice = await showModalBottomSheet<_ColorChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _ColorSheet(current: _currentTextColor());
      },
    );
    if (choice == null || !mounted) {
      return;
    }
    _applyTextColor(choice.hex);
  }

  void _applyTextColor(String? hex) {
    _controller.formatSelection(
      hex == null
          ? Attribute.clone(Attribute.color, null)
          : ColorAttribute(hex),
    );
    _focusNode.requestFocus();
  }

  // ───────────────────────────── إدراج صورة ─────────────────────────────

  Future<void> _insertImage() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 90,
      );
      if (picked == null) {
        return;
      }
      final List<int> bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) {
          _toast('تعذّر قراءة الصورة المختارة.');
        }
        return;
      }
      // الصورة تُحفظ داخل المستند كـ base64، فلا تحتاج مسار ملف.
      final String source =
          'data:${_imageMimeType(picked.name)};base64,${base64Encode(bytes)}';
      final TextSelection selection = _controller.selection;
      final int index = selection.isValid
          ? selection.start
          : _controller.document.length - 1;
      _controller.document.insert(index, BlockEmbed.image(source));
      _controller.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );
      _focusNode.requestFocus();
    } catch (error) {
      if (mounted) {
        _toast('تعذّر إدراج الصورة: $error');
      }
    }
  }

  String _imageMimeType(String fileName) {
    final String name = fileName.toLowerCase();
    if (name.endsWith('.png')) {
      return 'image/png';
    }
    if (name.endsWith('.gif')) {
      return 'image/gif';
    }
    if (name.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  // ───────────────────────────── إحصاءات ─────────────────────────────

  int get _wordCount {
    final String text = _controller.document
        .toPlainText()
        .replaceAll('\uFFFC', ' ')
        .trim();
    if (text.isEmpty) {
      return 0;
    }
    return text
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .length;
  }

  int get _characterCount =>
      _controller.document.toPlainText().replaceAll('\n', '').length;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

// ───────────────────────────── مكوّنات مساعدة ─────────────────────────────

/// زر واحد في شريط الأدوات، مع إبراز الزر عند تفعيل التنسيق.
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onPressed != null;
    final Color foreground = active
        ? scheme.onPrimary
        : (enabled ? scheme.onSurfaceVariant : scheme.outlineVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: active ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 42,
              height: 42,
              child: IconTheme(
                data: IconThemeData(color: foreground, size: 21),
                child: Center(child: icon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نتيجة اختيار لون: `hex == null` يعني إزالة لون النص.
class _ColorChoice {
  const _ColorChoice(this.hex);

  final String? hex;
}

/// لوحة اختيار لون النص.
class _ColorSheet extends StatelessWidget {
  const _ColorSheet({required this.current});

  final Color? current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        18 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لون النص',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              for (final Color color in _palette)
                _ColorDot(
                  color: color,
                  selected: current?.toARGB32() == color.toARGB32(),
                  onTap: () {
                    Navigator.of(context).pop(_ColorChoice(_hexOf(color)));
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(const _ColorChoice(null));
              },
              icon: const Icon(Icons.format_color_reset_outlined, size: 18),
              label: const Text('إزالة اللون'),
            ),
          ),
        ],
      ),
    );
  }
}

/// دائرة لون واحدة داخل اللوحة.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
