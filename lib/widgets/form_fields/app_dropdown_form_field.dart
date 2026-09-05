import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../consts.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Reusable searchable list-of-values field.
///
/// The picker opens as a centered dialog so long backend value lists stay
/// searchable and usable on both desktop and compact layouts.
class AppDropdownFormField<T> extends StatelessWidget {
  const AppDropdownFormField({
    required this.label,
    required this.items,
    required this.onChanged,
    super.key,
    this.value,
    this.hintText,
    this.dialogTitle,
    this.searchHintText,
    this.validator,
    this.enabled = true,
    this.loadItems,
  });

  final String label;
  final T? value;
  final String? hintText;
  final String? dialogTitle;
  final String? searchHintText;
  final List<AppDropdownOption<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Future<List<AppDropdownOption<T>>?> Function()? loadItems;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      enabled: enabled,
      builder: (field) {
        final selected = _findOption(field.value);

        Future<void> openPicker() async {
          final selectedValue = await _showValuePicker(context, field.value);
          if (selectedValue == null) return;
          field.didChange(selectedValue);
          onChanged(selectedValue);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSizes.labelLeftPadding,
                bottom: AppSpacing.xs,
              ),
              child: Text(label, style: AppTextStyles.fieldLabel),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? openPicker : null,
                borderRadius: BorderRadius.circular(AppRadii.field),
                child: InputDecorator(
                  isEmpty: selected == null,
                  decoration: InputDecoration(
                    hintText: hintText,
                    errorText: field.errorText,
                    enabled: enabled,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DropdownSuffixButton(
                            onPressed: enabled ? openPicker : null,
                            tooltip: 'Show options',
                            icon: Icons.more_horiz_rounded,
                          ),
                          if (selected != null)
                            _DropdownSuffixButton(
                              onPressed: enabled
                                  ? () {
                                      field.didChange(null);
                                      onChanged(null);
                                    }
                                  : null,
                              tooltip: 'Clear selection',
                              icon: Icons.close_rounded,
                              color: AppColors.error,
                              hoverColor: AppColors.dangerBackground,
                            ),
                        ],
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.inputMinHeight,
                    ),
                  ),
                  child: Text(
                    selected?.label ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.input,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  AppDropdownOption<T>? _findOption(T? selectedValue) {
    if (selectedValue == null) return null;
    for (final option in items) {
      if (option.value == selectedValue) return option;
    }
    return null;
  }

  Future<T?> _showValuePicker(BuildContext context, T? selectedValue) {
    return showDialog<T>(
      context: context,
      barrierColor: AppColors.dialogScrim,
      builder: (dialogContext) => _SearchableValueDialog<T>(
        title: dialogTitle ?? label,
        searchHintText: searchHintText ?? 'Search values',
        items: items,
        loadItems: loadItems,
        selectedValue: selectedValue,
      ),
    );
  }
}

class _DropdownSuffixButton extends StatelessWidget {
  const _DropdownSuffixButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.color = AppColors.iconMuted,
    this.hoverColor = AppColors.softSurface,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final Color color;
  final Color hoverColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      color: color,
      icon: Icon(icon, size: AppSizes.inputIconSize),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppSizes.inputActionSize),
        maximumSize: const Size.square(AppSizes.inputActionSize),
        padding: EdgeInsets.zero,
        hoverColor: hoverColor,
        highlightColor: hoverColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xxs),
        ),
      ),
    );
  }
}

class _SearchableValueDialog<T> extends StatefulWidget {
  const _SearchableValueDialog({
    required this.title,
    required this.searchHintText,
    required this.items,
    required this.selectedValue,
    this.loadItems,
  });

  final String title;
  final String searchHintText;
  final List<AppDropdownOption<T>> items;
  final T? selectedValue;
  final Future<List<AppDropdownOption<T>>?> Function()? loadItems;

  @override
  State<_SearchableValueDialog<T>> createState() =>
      _SearchableValueDialogState<T>();
}

class _SearchableValueDialogState<T> extends State<_SearchableValueDialog<T>> {
  final _searchController = TextEditingController();
  String _query = '';
  late List<AppDropdownOption<T>> _items;
  bool _isLoading = false;
  bool _loadFailed = false;

  List<AppDropdownOption<T>> get _filteredItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items
        .where((option) => option.label.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    if (widget.loadItems != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadBackendItems();
      });
    }
  }

  Future<void> _loadBackendItems() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    final loadedItems = await widget.loadItems?.call();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadFailed = loadedItems == null;
      if (loadedItems != null) _items = loadedItems;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final availableHeight = math.max(1, size.height - (AppSpacing.xxl * 2));
    final dialogHeight = math
        .min(AppSizes.dropdownDialogHeight, availableHeight)
        .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.section),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppSizes.dropdownDialogWidth),
        child: SizedBox(
          height: dialogHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyles.heading(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: widget.searchHintText,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                    fillColor: AppColors.softSurface,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadFailed
                    ? _ValueLoadFailure(onRetry: _loadBackendItems)
                    : _filteredItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'No values match your search.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xxs),
                        itemBuilder: (context, index) {
                          final option = _filteredItems[index];
                          final selected = option.value == widget.selectedValue;
                          return Material(
                            color: selected
                                ? AppColors.primaryLight
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.field),
                            child: InkWell(
                              onTap: () =>
                                  Navigator.of(context).pop(option.value),
                              borderRadius: BorderRadius.circular(
                                AppRadii.field,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: AppTextStyles.body.copyWith(
                                          color: selected
                                              ? AppColors.primaryDark
                                              : AppColors.textPrimary,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueLoadFailure extends StatelessWidget {
  const _ValueLoadFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.iconMuted,
              size: 34,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Based elements could not be loaded from the server.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
