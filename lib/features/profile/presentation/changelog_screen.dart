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
          _UpdateBlock(
            version: "1.3.0",
            date: "June 10, 2026",
            changes: [
              "Deep Lyric Search: Can't remember a song title? Just type a phrase from the chorus or bridge and the search engine will find it!",
              "Improved UI for lyrics and chords view mode.",
              "Zoom control increase or decrease font size",
            ],
          ),
          Divider(height: 32),
          _UpdateBlock(
            version: "1.2.0",
            date: "March 20, 2026", // Today's date!
            changes: [
              "Brand New Home Dashboard! A beautiful, Spotify-inspired discovery screen. 🎨",
              "Song Categories: Easily browse by 'Deep Worship', 'High Praise', or 'Hymns' with new quick-tap hero cards. 🔥",
              "Browse by Key: Instantly find songs in your preferred key using the new horizontal shelf. 🎹",
              "Dedicated Search Tab: Filtering and searching now live in their own tab so you never lose your bottom navigation bar! 🔍",
              "Smart Badges: Song lists now feature color-coded tags so you can quickly see a song's vibe at a glance. 🏷️",
              "Redesigned Chord Mode: Professional sheet-music feel with a permanent 2-column layout on mobile. 🎼",
              "Improved Typography: Heavier chords, italicized section headers, and a clean new metadata header. ✨",
            ],
          ),
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
