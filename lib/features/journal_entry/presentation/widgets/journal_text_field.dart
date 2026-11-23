import 'package:material_ui/material_ui.dart';
import '../../../../core/constants/app_constants.dart';

class JournalTextField extends StatefulWidget {
  final TextEditingController controller;

  const JournalTextField({
    super.key,
    required this.controller,
  });

  @override
  State<JournalTextField> createState() => _JournalTextFieldState();
}

class _JournalTextFieldState extends State<JournalTextField> {
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _updateCounts();
    widget.controller.addListener(_updateCounts);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCounts);
    super.dispose();
  }

  void _updateCounts() {
    final text = widget.controller.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (words != _wordCount && mounted) {
      setState(() {
        _wordCount = words;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 16,
              letterSpacing: 0.1,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.writeYourThoughts,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                height: 1.6,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Count row
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_wordCount words • ${widget.controller.text.length} ${AppStrings.characters}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
