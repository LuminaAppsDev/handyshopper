/// The item-list columns a user can show or hide per list.
enum ItemColumn {
  /// Quantity (with unit when set).
  quantity,

  /// Price.
  price,

  /// Priority 1–5.
  priority,

  /// Aisle.
  aisle,

  /// Date (for dated lists).
  date,
}

/// The default column set (quantity + price), reproducing the pre-Phase-5 row.
final int kDefaultColumns = _bit(ItemColumn.quantity) | _bit(ItemColumn.price);

int _bit(ItemColumn column) => 1 << column.index;

/// Resolves stored [flags] to an effective set: a stored `0` means "never
/// configured" and falls back to [kDefaultColumns] (so existing lists keep the
/// quantity+price row without a migration).
int effectiveColumns(int flags) => flags == 0 ? kDefaultColumns : flags;

/// Whether [column] is enabled in [flags] (after the `0 → default` rule).
bool hasColumn(int flags, ItemColumn column) =>
    (effectiveColumns(flags) & _bit(column)) != 0;

/// Returns [flags] with [column] turned [on] or off.
int toggleColumn(int flags, ItemColumn column, {required bool on}) {
  final base = effectiveColumns(flags);
  final updated = on ? base | _bit(column) : base & ~_bit(column);
  // Keep a non-zero marker so an all-off selection isn't re-expanded to the
  // default; fall back to the default only when nothing was ever set.
  return updated == 0 ? _bit(ItemColumn.quantity) : updated;
}
