import 'package:flutter/material.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/data/models/lyric_line_model.dart';
import 'package:worship_lamal/features/songs/presentation/screens/song_detail_screen.dart';

/// Displays a section of lyrics with appropriate styling based on section type
/// Matches the Kotlin/Compose design with surface containers and accent bars
class LyricSectionWidget extends StatelessWidget {
  final SectionBlock section;

  const LyricSectionWidget({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final config = _getSectionConfig(section.sectionType);
    final hasBlock = config.showBackground;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: AppConstants.spacingSm,
      ),
      child: hasBlock
          ? _buildBlockSection(context, config)
          : _buildSimpleSection(context, config),
    );
  }

  Widget _buildBlockSection(BuildContext context, _SectionConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Stack(
        children: [
          // Accent bar on the left
          if (config.accentColor != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: config.accentColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.radiusLg),
                    bottomLeft: Radius.circular(AppConstants.radiusLg),
                  ),
                ),
              ),
            ),
          // Content with padding
          Padding(
            padding: EdgeInsets.only(
              left: config.accentColor != null ? 22 : 12,
              top: 12,
              right: 12,
              bottom: 12,
            ),
            child: _buildSectionContent(context, config),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSection(BuildContext context, _SectionConfig config) {
    return _buildSectionContent(context, config);
  }

  Widget _buildSectionContent(BuildContext context, _SectionConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderPill(title: section.title),
        SizedBox(height: AppConstants.spacingSm),
        ...section.lines.map(
          (line) => Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              line.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                height: 1.6,
                fontWeight: config.fontWeight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  _SectionConfig _getSectionConfig(SongSection type) {
    switch (type) {
      case SongSection.chorus:
        return _SectionConfig(
          backgroundColor: AppColors.chorusBackground,
          accentColor: AppColors.chorusBorder.withOpacity(0.24),
          showBackground: true,
          fontWeight: FontWeight.w500,
        );
      case SongSection.bridge:
        return _SectionConfig(
          backgroundColor: AppColors.bridgeBackground,
          accentColor: AppColors.bridgeBorder.withOpacity(0.20),
          showBackground: true,
          fontWeight: FontWeight.w500,
        );
      case SongSection.preChorus:
        return _SectionConfig(
          backgroundColor: AppColors.preChorusBackground,
          accentColor: AppColors.preChorusBorder.withOpacity(0.20),
          showBackground: true,
          fontWeight: FontWeight.w500,
        );
      case SongSection.verse:
      default:
        return _SectionConfig(
          backgroundColor: AppColors.verseBackground,
          accentColor: null,
          showBackground: false,
          fontWeight: FontWeight.normal,
        );
    }
  }
}

/// Section header pill/badge
class _SectionHeaderPill extends StatelessWidget {
  final String title;

  const _SectionHeaderPill({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Configuration for section styling
class _SectionConfig {
  final Color backgroundColor;
  final Color? accentColor;
  final bool showBackground;
  final FontWeight fontWeight;

  const _SectionConfig({
    required this.backgroundColor,
    required this.accentColor,
    required this.showBackground,
    required this.fontWeight,
  });
}
