import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;

  const AppSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Search notifications',
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                  if (query.isNotEmpty)
                    GestureDetector(
                      onTap: () => onChanged(''),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}
