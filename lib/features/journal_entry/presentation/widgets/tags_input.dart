import 'package:material_ui/material_ui.dart';
import '../../../../core/constants/app_constants.dart';

class TagsInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagsInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagsInput> createState() => _TagsInputState();
}

class _TagsInputState extends State<TagsInput> {
  final _tagController = TextEditingController();

  static const List<String> _suggestions = [
    'gratitude',
    'reflection',
    'work',
    'family',
    'health',
    'mindfulness',
  ];

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag([String? customTag]) {
    final raw = (customTag ?? _tagController.text).trim().replaceAll('#', '');
    if (raw.isNotEmpty && !widget.tags.contains(raw)) {
      final newTags = [...widget.tags, raw];
      widget.onTagsChanged(newTags);
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    final newTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableSuggestions = _suggestions.where((s) => !widget.tags.contains(s)).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(Optional)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Active tags display
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.tags.map((tag) {
              return InputChip(
                label: Text('#$tag'),
                onDeleted: () => _removeTag(tag),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                deleteIconColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Tag input row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: 'Add a tag (e.g. gratitude, ideas)...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    prefixText: '#',
                    prefixStyle: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _addTag(),
              icon: const Icon(Icons.add, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                ),
              ),
            ),
          ],
        ),

        // Suggested prompts
        if (widget.tags.length < 3 && availableSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Suggestions: ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                ...availableSuggestions.map((sug) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text('+$sug'),
                      onPressed: () => _addTag(sug),
                      padding: EdgeInsets.zero,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: theme.colorScheme.surfaceContainerLowest,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
