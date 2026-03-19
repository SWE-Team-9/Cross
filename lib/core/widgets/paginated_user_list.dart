import 'package:flutter/material.dart';

/// A generic, reusable paginated list widget for social user lists.
/// Used by Followers, Following, Likes, and any similar user-list screen.
///
/// Example usage:
/// ```dart
/// PaginatedUserList<UserEntity>(
///   fetcher: (page) => repository.getFollowers(userId, page: page),
///   itemBuilder: (context, user) => UserListTile(user: user),
///   emptyMessage: 'No followers yet',
/// )
/// ```
class PaginatedUserList<T> extends StatefulWidget {
  /// Called with the current page number (1-based).
  /// Must return a list of items for that page.
  final Future<List<T>> Function(int page) fetcher;

  /// Builds one row widget from a data item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Text shown in the empty state.
  final String emptyMessage;

  /// Icon shown above the empty message.
  final IconData emptyIcon;

  /// How many items per page. Used to detect if more pages exist.
  final int pageSize;

  const PaginatedUserList({
    super.key,
    required this.fetcher,
    required this.itemBuilder,
    this.emptyMessage = 'Nothing here yet',
    this.emptyIcon = Icons.people_outline,
    this.pageSize = 20,
  });

  @override
  State<PaginatedUserList<T>> createState() => _PaginatedUserListState<T>();
}

class _PaginatedUserListState<T> extends State<PaginatedUserList<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPage(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger load-more when within 200px of the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _loadPage({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (isRefresh) {
        _items.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final results = await widget.fetcher(_currentPage);
      setState(() {
        _items.addAll(results);
        // If fewer items than a full page, no more pages exist
        _hasMore = results.length >= widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final results = await widget.fetcher(_currentPage);
      setState(() {
        _items.addAll(results);
        _hasMore = results.length >= widget.pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      // Roll back page counter so a retry requests the same page
      _currentPage--;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── First-load spinner ──────────────────────────────────────────────────
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── Error (no items loaded yet) ─────────────────────────────────────────
    if (_errorMessage != null && _items.isEmpty) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: () => _loadPage(isRefresh: true),
      );
    }

    // ── Empty ───────────────────────────────────────────────────────────────
    if (_items.isEmpty) {
      return _EmptyState(
        message: widget.emptyMessage,
        icon: widget.emptyIcon,
      );
    }

    // ── Populated list ──────────────────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: () => _loadPage(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        // AlwaysScrollableScrollPhysics ensures pull-to-refresh works
        // even when the list doesn't fill the screen
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            // Load-more spinner at the very bottom
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}