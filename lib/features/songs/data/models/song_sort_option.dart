enum SongSortOption {
  titleAz('Title (A-Z)'),
  // titleZa('Title (Z-A)'),
  artistAz('Artist (A-Z)'),
  newest('Newest Added'),
  recentlyViewed("Recently Viewed");
  // oldest('Oldest Added');

  final String label;
  const SongSortOption(this.label);
}
