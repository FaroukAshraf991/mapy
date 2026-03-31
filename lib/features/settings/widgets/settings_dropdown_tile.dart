import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

/// A styled dropdown tile for settings options
class SettingsDropdownTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const SettingsDropdownTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title,
          style:
              TextStyle(fontWeight: FontWeight.w500, fontSize: context.sp(15))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: context.sp(13))),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        onChanged: onChanged,
        items: items.entries.map((e) {
          return DropdownMenuItem(
              value: e.key,
              child: Text(e.value, style: TextStyle(fontSize: context.sp(14))));
        }).toList(),
      ),
    );
  }
}
