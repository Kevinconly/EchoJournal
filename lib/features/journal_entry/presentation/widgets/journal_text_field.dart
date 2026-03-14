import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: AppStrings.writeYourThoughts,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
            style: const TextStyle(fontSize: 16),
            onChanged: (value) {
              setState(() {}); // Rebuild to update character count
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Character count
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${widget.controller.text.length} ${AppStrings.characters}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
