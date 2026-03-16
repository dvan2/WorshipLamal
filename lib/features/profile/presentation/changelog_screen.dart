import 'package:flutter/material.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("What's New")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // NEW UPDATE BLOCK
          _UpdateBlock(
            version: "1.1.2",
            date: "Today",
            changes: [
              "Completely redesigned Chord Mode for a professional sheet-music feel. 🎼",
              "New permanent 2-column layout on mobile to view more of the song without scrolling. 📱",
              "Improved typography with heavier chords and italicized section headers for faster reading. ✨",
              "Added a clean metadata header for Title, Artist, Key, and BPM. 📄",
            ],
          ),
          Divider(height: 32),
          // PREVIOUS UPDATES
          _UpdateBlock(
            version: "1.1.1",
            date: "Feb 4, 2026",
            changes: [
              "Improved Chord View: Better spacing and alignment for easier reading. 🎸",
              "New Domain: Rebranded to worshiplamal.com! 🌐",
              "Default View: Songs now open in Lyrics mode by default. 📝",
            ],
          ),
          Divider(height: 32),
          _UpdateBlock(
            version: "1.1.0",
            date: "Oct 24, 2025",
            changes: [
              "Added 'Recently Viewed' sorting! 🕒",
              "You can now see key changes instantly in setlists.",
              "Fixed issue with undoing song removal.",
            ],
          ),
          Divider(height: 32),
          _UpdateBlock(
            version: "1.0.0",
            date: "Oct 1, 2025",
            changes: [
              "Initial Release",
              "Browse songs and create setlists.",
              "Save personalized keys",
              "View chords",
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateBlock extends StatelessWidget {
  final String version;
  final String date;
  final List<String> changes;

  const _UpdateBlock({
    required this.version,
    required this.date,
    required this.changes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Version $version",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(date, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        ...changes.map(
          (change) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(change)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
