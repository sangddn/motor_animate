import 'package:flutter/widgets.dart';

import '../../motor_animate.dart';

/// Describes a single rendered entry managed by [MultiAnimatedPresence].
///
/// Same-key updates reuse the same logical entry. When an item is removed from
/// [MultiAnimatedPresence.items], the entry remains rendered with
/// [isExiting] set to `true` until [MultiAnimatedPresence.onDisappear]
/// completes.
@immutable
class MultiAnimatedPresenceEntry<T, K extends Object> {
  const MultiAnimatedPresenceEntry._({
    required this.key,
    required this.item,
    required this.renderIndex,
    required this.dataIndex,
    required this.isExiting,
  });

  /// Stable identity for the logical item.
  final K key;

  /// Latest data associated with this entry.
  ///
  /// For exiting entries this is the last value seen before the item was
  /// removed from [MultiAnimatedPresence.items].
  final T item;

  /// Index in the rendered collection managed by [MultiAnimatedPresence].
  final int renderIndex;

  /// Index in the current [MultiAnimatedPresence.items] list.
  ///
  /// This is `null` while [isExiting] is `true`.
  final int? dataIndex;

  /// Whether this entry is currently playing its exit transition.
  final bool isExiting;
}

/// Builds the stable child for a presence-managed entry.
///
/// Return the plain widget for the row/item. [MultiAnimatedPresence] owns the
/// outer [Animate] wrapper and applies [onAppear] / [onDisappear] around it.
typedef MultiAnimatedPresenceItemBuilder<T, K extends Object> = Widget Function(
  BuildContext context,
  MultiAnimatedPresenceEntry<T, K> entry,
);

/// Builds the animated wrapper for an entry transition.
typedef MultiAnimatedPresenceTransitionBuilder<T, K extends Object> = Widget
    Function(
  BuildContext context,
  MultiAnimatedPresenceEntry<T, K> entry,
  Animate child,
);

/// Builds the host collection using a presence-managed delegate.
///
/// The delegate can be consumed by builder-based widgets such as
/// [ListView.builder] / [SliverList.builder], or eager/custom hosts via
/// [MultiAnimatedPresenceDelegate.buildChildren].
typedef MultiAnimatedPresenceBuilder<T, K extends Object> = Widget Function(
  BuildContext context,
  MultiAnimatedPresenceDelegate<T, K> delegate,
);

/// Delegate describing the current presence-managed collection.
///
/// This exposes builder-friendly primitives plus eager helpers so
/// [MultiAnimatedPresence] can drive a wide range of underlying list/sliver
/// implementations without owning the scrollable widget itself.
@immutable
class MultiAnimatedPresenceDelegate<T, K extends Object> {
  const MultiAnimatedPresenceDelegate._({
    required this.entries,
    required NullableIndexedWidgetBuilder itemBuilder,
    required ChildIndexGetter findChildIndexCallback,
    required int? Function(K key) indexOfKey,
  })  : _itemBuilder = itemBuilder,
        _findChildIndexCallback = findChildIndexCallback,
        _indexOfKey = indexOfKey;

  /// Rendered entries in display order, including exiting entries.
  final List<MultiAnimatedPresenceEntry<T, K>> entries;

  final NullableIndexedWidgetBuilder _itemBuilder;
  final ChildIndexGetter _findChildIndexCallback;
  final int? Function(K key) _indexOfKey;

  /// Number of rendered entries, including exiting entries.
  int get itemCount => entries.length;

  /// Builder callback suitable for [ListView.builder] and [SliverList.builder].
  NullableIndexedWidgetBuilder get itemBuilder => _itemBuilder;

  /// Key lookup callback suitable for builder-based slivers/lists that support
  /// child reattachment by key.
  ChildIndexGetter get findChildIndexCallback => _findChildIndexCallback;

  /// Finds the current render index for a logical item key.
  int? indexOfKey(K key) => _indexOfKey(key);

  /// Builds a rendered child at [index].
  Widget buildItem(BuildContext context, int index) =>
      _itemBuilder(context, index)!;

  /// Builds all rendered children eagerly.
  List<Widget> buildChildren(BuildContext context) => List<Widget>.generate(
        itemCount,
        (int index) => buildItem(context, index),
        growable: false,
      );

  /// Creates a [SliverChildBuilderDelegate] for hosts that prefer a delegate
  /// object over separate `itemCount` / `itemBuilder` parameters.
  SliverChildBuilderDelegate buildSliverChildDelegate({
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    int semanticIndexOffset = 0,
  }) {
    return SliverChildBuilderDelegate(
      _itemBuilder,
      findChildIndexCallback: _findChildIndexCallback,
      childCount: itemCount,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      semanticIndexOffset: semanticIndexOffset,
    );
  }
}

/// {@template motor_animate.multi_animated_presence}
/// Manages keyed presence for collection items while leaving host layout to the caller.
///
/// [MultiAnimatedPresence] diffs [items] by [keyOf], keeps removed items
/// mounted long enough for [onDisappear] to finish, and exposes a
/// [MultiAnimatedPresenceDelegate] to [builder]. This makes it suitable for
/// `ListView.builder`, `SliverList.builder`, custom sliver hosts, and eager
/// child collections.
///
/// Same key means same logical item. Updating the data for an existing key does
/// not trigger a leave/enter cycle. Removing a key starts [onDisappear], and
/// reintroducing that same key before exit completes revives the entry and
/// replays [onAppear].
///
/// This widget is intentionally focused on insertion/removal presence. It is
/// not an animated switcher replacement, and it does not choreograph arbitrary
/// reorder animations.
///
/// ```dart
/// MultiAnimatedPresence<Message, String>(
///   items: messages,
///   keyOf: (message) => message.id,
///   itemBuilder: (context, entry) => MessageTile(message: entry.item),
///   onAppear: (context, entry, child) => child.fadeIn().slideY(begin: 0.08),
///   onDisappear: (context, entry, child) =>
///       child.fadeOut().sizeY(alignment: -1),
///   builder: (context, delegate) {
///     return ListView.builder(
///       itemCount: delegate.itemCount,
///       itemBuilder: delegate.itemBuilder,
///       findChildIndexCallback: delegate.findChildIndexCallback,
///     );
///   },
/// )
/// ```
/// {@endtemplate}
class MultiAnimatedPresence<T, K extends Object> extends StatefulWidget {
  /// Creates a [MultiAnimatedPresence] widget.
  ///
  /// Parameters:
  /// - [items] - The current data items, in desired active display order.
  /// - [keyOf] - Returns the stable identity for each logical item.
  /// - [itemBuilder] - Builds the stable child for a presence-managed entry.
  /// - [builder] - Builds the host collection from the current delegate.
  /// - [onAppear] - Builds the animated wrapper for active entries. Leave this null to use the default enter transition.
  /// - [onDisappear] - Builds the animated wrapper for exiting entries. Leave this null to use the default exit transition.
  ///
  /// {@macro motor_animate.multi_animated_presence}
  const MultiAnimatedPresence({
    super.key,
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    required this.builder,
    MultiAnimatedPresenceTransitionBuilder<T, K>? onAppear,
    MultiAnimatedPresenceTransitionBuilder<T, K>? onDisappear,
  })  : onAppear = onAppear ?? _defaultOnAppear,
        onDisappear = onDisappear ?? _defaultOnDisappear;

  /// Default enter transition used when [onAppear] is omitted.
  static Widget _defaultOnAppear<T, K extends Object>(
    BuildContext context,
    MultiAnimatedPresenceEntry<T, K> entry,
    Animate child,
  ) {
    return child.fadeIn();
  }

  /// Default exit transition used when [onDisappear] is omitted.
  static Widget _defaultOnDisappear<T, K extends Object>(
    BuildContext context,
    MultiAnimatedPresenceEntry<T, K> entry,
    Animate child,
  ) {
    return child.fadeOut();
  }

  /// Current data items, in desired active display order.
  final List<T> items;

  /// Returns the stable identity for each logical item.
  ///
  /// Keys must be unique within [items].
  final K Function(T item) keyOf;

  /// Builds the stable child for a presence-managed entry.
  final MultiAnimatedPresenceItemBuilder<T, K> itemBuilder;

  /// Builds the host collection from the current delegate.
  final MultiAnimatedPresenceBuilder<T, K> builder;

  /// Builds the animated wrapper for active entries.
  final MultiAnimatedPresenceTransitionBuilder<T, K> onAppear;

  /// Builds the animated wrapper for exiting entries.
  final MultiAnimatedPresenceTransitionBuilder<T, K> onDisappear;

  @override
  State<MultiAnimatedPresence<T, K>> createState() =>
      _MultiAnimatedPresenceState<T, K>();
}

class _MultiAnimatedPresenceState<T, K extends Object>
    extends State<MultiAnimatedPresence<T, K>> {
  final _entriesByKey = <K, _TrackedPresenceEntry<T, K>>{};
  var _renderKeys = <K>[];

  @override
  void initState() {
    super.initState();
    _syncItems(widget.items);
  }

  @override
  void didUpdateWidget(covariant MultiAnimatedPresence<T, K> oldWidget) {
    _syncItems(widget.items);
    super.didUpdateWidget(oldWidget);
  }

  bool _debugValidateUniqueKeys(List<T> items) {
    late final Set<K> seen = <K>{};
    for (final T item in items) {
      final K key = widget.keyOf(item);
      assert(
        seen.add(key),
        'MultiAnimatedPresence requires unique keys. Duplicate key: $key',
      );
    }
    return true;
  }

  void _syncItems(List<T> items) {
    assert(_debugValidateUniqueKeys(items));

    final oldRenderKeys = List<K>.from(_renderKeys);
    final incomingByKey = <K, _IncomingPresenceEntry<T>>{};
    final activeKeysInOrder = <K>[];

    for (int index = 0; index < items.length; index++) {
      final T item = items[index];
      final K key = widget.keyOf(item);
      incomingByKey[key] =
          _IncomingPresenceEntry<T>(item: item, dataIndex: index);
      activeKeysInOrder.add(key);
    }

    for (final MapEntry<K, _TrackedPresenceEntry<T, K>> entry
        in _entriesByKey.entries) {
      final _IncomingPresenceEntry<T>? incoming = incomingByKey[entry.key];
      final _TrackedPresenceEntry<T, K> tracked = entry.value;

      if (incoming == null) {
        if (!tracked.isExiting) {
          tracked.isExiting = true;
          tracked.dataIndex = null;
          tracked.phaseToken++;
          tracked.scheduledExitToken = null;
        }
        continue;
      }

      tracked.item = incoming.item;
      tracked.dataIndex = incoming.dataIndex;
      if (tracked.isExiting) {
        tracked.isExiting = false;
        tracked.phaseToken++;
        tracked.scheduledExitToken = null;
      }
    }

    for (final MapEntry<K, _IncomingPresenceEntry<T>> entry
        in incomingByKey.entries) {
      _entriesByKey.putIfAbsent(
        entry.key,
        () => _TrackedPresenceEntry<T, K>(
          key: entry.key,
          item: entry.value.item,
          dataIndex: entry.value.dataIndex,
        ),
      );
    }

    _renderKeys = _mergeRenderKeys(
      oldRenderKeys: oldRenderKeys,
      activeKeysInOrder: activeKeysInOrder,
    );
  }

  List<K> _mergeRenderKeys({
    required List<K> oldRenderKeys,
    required List<K> activeKeysInOrder,
  }) {
    if (oldRenderKeys.isEmpty) return List<K>.from(activeKeysInOrder);

    final Set<K> activeKeySet = activeKeysInOrder.toSet();
    final Map<K, List<K>> exitingBefore = <K, List<K>>{};
    final List<K> trailingExiting = <K>[];
    K? nextActiveAnchor;

    for (int index = oldRenderKeys.length - 1; index >= 0; index--) {
      final K key = oldRenderKeys[index];
      final _TrackedPresenceEntry<T, K>? tracked = _entriesByKey[key];
      if (tracked == null) continue;

      if (!tracked.isExiting && activeKeySet.contains(key)) {
        nextActiveAnchor = key;
        continue;
      }

      if (!tracked.isExiting) continue;

      if (nextActiveAnchor == null) {
        trailingExiting.add(key);
      } else {
        (exitingBefore[nextActiveAnchor] ??= <K>[]).add(key);
      }
    }

    final List<K> merged = <K>[];
    for (final K activeKey in activeKeysInOrder) {
      final List<K>? anchoredExits = exitingBefore[activeKey];
      if (anchoredExits != null) {
        merged.addAll(anchoredExits.reversed);
      }
      merged.add(activeKey);
    }
    merged.addAll(trailingExiting.reversed);
    return merged;
  }

  Widget? _buildItem(BuildContext context, int index) {
    if (index < 0 || index >= _renderKeys.length) return null;
    final K key = _renderKeys[index];
    final _TrackedPresenceEntry<T, K> tracked = _entriesByKey[key]!;
    final MultiAnimatedPresenceEntry<T, K> entry = MultiAnimatedPresenceEntry._(
      key: tracked.key,
      item: tracked.item,
      renderIndex: index,
      dataIndex: tracked.dataIndex,
      isExiting: tracked.isExiting,
    );
    final int phaseToken = tracked.phaseToken;

    final Animate child = Animate(
      key: ValueKey<int>(phaseToken),
      replayOnChange: phaseToken,
      child: widget.itemBuilder(context, entry),
    );

    if (!entry.isExiting) {
      return KeyedSubtree(
        key: _MultiAnimatedPresenceItemKey<K>(entry.key),
        child: widget.onAppear(context, entry, child),
      );
    }

    final Widget exitingChild = widget.onDisappear(context, entry, child);
    _scheduleExitRemovalIfNeeded(entry.key, phaseToken, child.duration);
    return KeyedSubtree(
      key: _MultiAnimatedPresenceItemKey<K>(entry.key),
      child: exitingChild,
    );
  }

  void _scheduleExitRemovalIfNeeded(
    K key,
    int phaseToken,
    Duration duration,
  ) {
    final _TrackedPresenceEntry<T, K>? tracked = _entriesByKey[key];
    if (tracked == null || tracked.scheduledExitToken == phaseToken) return;
    tracked.scheduledExitToken = phaseToken;

    final Duration delay =
        duration <= Duration.zero ? const Duration(microseconds: 1) : duration;

    Future<void>.delayed(delay, () {
      _removeExitedEntry(key, phaseToken);
    });
  }

  void _removeExitedEntry(K key, int phaseToken) {
    if (!mounted) return;
    final _TrackedPresenceEntry<T, K>? tracked = _entriesByKey[key];
    if (tracked == null ||
        !tracked.isExiting ||
        tracked.phaseToken != phaseToken) {
      return;
    }

    setState(() {
      final _TrackedPresenceEntry<T, K>? current = _entriesByKey[key];
      if (current == null ||
          !current.isExiting ||
          current.phaseToken != phaseToken) {
        return;
      }

      _entriesByKey.remove(key);
      _renderKeys = _renderKeys
          .where((K renderKey) => renderKey != key)
          .toList(growable: false);
    });
  }

  int? _findChildIndex(Key key) {
    if (key is! _MultiAnimatedPresenceItemKey<K>) return null;
    return _indexOfKey(key.value);
  }

  int? _indexOfKey(K key) {
    final int index = _renderKeys.indexOf(key);
    return index == -1 ? null : index;
  }

  @override
  Widget build(BuildContext context) {
    final List<MultiAnimatedPresenceEntry<T, K>> entries =
        List<MultiAnimatedPresenceEntry<T, K>>.generate(
      _renderKeys.length,
      (int index) {
        final _TrackedPresenceEntry<T, K> tracked =
            _entriesByKey[_renderKeys[index]]!;
        return MultiAnimatedPresenceEntry<T, K>._(
          key: tracked.key,
          item: tracked.item,
          renderIndex: index,
          dataIndex: tracked.dataIndex,
          isExiting: tracked.isExiting,
        );
      },
      growable: false,
    );

    final MultiAnimatedPresenceDelegate<T, K> delegate =
        MultiAnimatedPresenceDelegate<T, K>._(
      entries: List<MultiAnimatedPresenceEntry<T, K>>.unmodifiable(entries),
      itemBuilder: _buildItem,
      findChildIndexCallback: _findChildIndex,
      indexOfKey: _indexOfKey,
    );

    return widget.builder(context, delegate);
  }
}

class _TrackedPresenceEntry<T, K extends Object> {
  _TrackedPresenceEntry({
    required this.key,
    required this.item,
    required this.dataIndex,
  });

  final K key;
  T item;
  int? dataIndex;
  bool isExiting = false;
  int phaseToken = 0;
  int? scheduledExitToken;
}

class _IncomingPresenceEntry<T> {
  const _IncomingPresenceEntry({
    required this.item,
    required this.dataIndex,
  });

  final T item;
  final int dataIndex;
}

class _MultiAnimatedPresenceItemKey<K extends Object> extends ValueKey<K> {
  const _MultiAnimatedPresenceItemKey(super.value);
}
