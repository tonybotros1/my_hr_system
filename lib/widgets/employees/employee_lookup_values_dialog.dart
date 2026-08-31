import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/employee_controllers/employees_controller.dart';
import '../../models/employees/employee_model.dart';
import '../../services/browser_dialog_history.dart';
import '../dialogs/app_alert_dialog.dart';
import '../form_fields/app_text_form_field.dart';

Future<void> showEmployeeLookupValuesDialog(
  BuildContext context, {
  required EmployeesController controller,
  required String code,
  required String title,
  required String singularTitle,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final history = BrowserDialogHistory.open(() {
    if (navigator.canPop()) navigator.pop<void>();
  });
  try {
    await Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.editor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height - 48,
            child: _LookupValuesManager(
              controller: controller,
              code: code,
              title: title,
              singularTitle: singularTitle,
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: AppColors.dialogScrim,
    );
  } finally {
    history.complete();
  }
}

class _LookupValuesManager extends StatefulWidget {
  const _LookupValuesManager({
    required this.controller,
    required this.code,
    required this.title,
    required this.singularTitle,
  });

  final EmployeesController controller;
  final String code;
  final String title;
  final String singularTitle;

  @override
  State<_LookupValuesManager> createState() => _LookupValuesManagerState();
}

class _LookupValuesManagerState extends State<_LookupValuesManager> {
  final _search = TextEditingController();
  Map<String, dynamic> _values = const {};
  bool _loading = true;

  Iterable<MapEntry<String, dynamic>> get _filteredValues {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _values.entries;
    return _values.entries.where((entry) {
      final raw = entry.value;
      if (raw is! Map) return false;
      return employeeString(raw['name']).toLowerCase().contains(query);
    });
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    final values = await widget.controller.listValues(
      widget.code,
      refresh: true,
    );
    if (!mounted) return;
    setState(() {
      _values = values;
      _loading = false;
    });
  }

  Future<void> _createValue() async {
    final saved = await _showValueEditorDialog(
      context,
      title: 'New ${widget.singularTitle}',
      onSave: (name) => widget.controller.addListValue(widget.code, name),
    );
    if (saved) await _reload();
  }

  Future<void> _editValue(String id, String name) async {
    final saved = await _showValueEditorDialog(
      context,
      title: 'Edit ${widget.singularTitle}',
      initialName: name,
      onSave: (newName) =>
          widget.controller.updateListValue(widget.code, id, newName),
    );
    if (saved) await _reload();
  }

  Future<void> _deleteValue(String id, String name) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete $name?',
      message: 'This value will be removed permanently from ${widget.title}.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    final deleted = await widget.controller.deleteListValue(widget.code, id);
    if (deleted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final visibleValues = _filteredValues.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          color: AppColors.primaryDark,
          child: Row(
            children: [
              const Icon(
                Icons.list_alt_rounded,
                size: 20,
                color: AppColors.surface,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading(
                    fontSize: 19,
                  ).copyWith(color: AppColors.surface),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: Get.back<void>,
                color: AppColors.surface,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSizes.inputMinHeight,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.input,
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.title.toLowerCase()}…',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: AppSizes.inputIconSize,
                      ),
                      prefixIconConstraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: AppSizes.inputMinHeight,
                      ),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: AppSizes.inputIconSize,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _loading ? null : _createValue,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Value'),
              ),
            ],
          ),
        ),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: AppColors.tableHeader,
          child: Row(
            children: [
              SizedBox(
                width: 94,
                child: Text('ACTIONS', style: AppTextStyles.tableHeader),
              ),
              Expanded(child: Text('NAME', style: AppTextStyles.tableHeader)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : visibleValues.isEmpty
              ? Center(
                  child: Text(
                    _search.text.isEmpty
                        ? 'No values have been added yet.'
                        : 'No values match your search.',
                    style: AppTextStyles.bodyMuted,
                  ),
                )
              : ListView.separated(
                  itemCount: visibleValues.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, index) {
                    final entry = visibleValues[index];
                    final raw = entry.value;
                    final name = raw is Map ? employeeString(raw['name']) : '';
                    return SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 98,
                              child: Row(
                                children: [
                                  _TableActionButton(
                                    tooltip: 'Delete',
                                    icon: Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    onPressed: () =>
                                        _deleteValue(entry.key, name),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  _TableActionButton(
                                    tooltip: 'Edit',
                                    icon: Icons.edit_outlined,
                                    color: AppColors.primaryDark,
                                    onPressed: () =>
                                        _editValue(entry.key, name),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.tableBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Text(
            '${visibleValues.length} ${visibleValues.length == 1 ? 'value' : 'values'} shown',
            style: AppTextStyles.listCount,
          ),
        ),
      ],
    );
  }
}

class _TableActionButton extends StatelessWidget {
  const _TableActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: SizedBox.square(
          dimension: 34,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

Future<bool> _showValueEditorDialog(
  BuildContext context, {
  required String title,
  required Future<bool> Function(String name) onSave,
  String initialName = '',
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final history = BrowserDialogHistory.open(() {
    if (navigator.canPop()) navigator.pop(false);
  });
  try {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierColor: AppColors.dialogScrim,
          builder: (context) => _ValueEditorDialog(
            title: title,
            initialName: initialName,
            onSave: onSave,
          ),
        ) ==
        true;
  } finally {
    history.complete();
  }
}

class _ValueEditorDialog extends StatefulWidget {
  const _ValueEditorDialog({
    required this.title,
    required this.initialName,
    required this.onSave,
  });

  final String title;
  final String initialName;
  final Future<bool> Function(String name) onSave;

  @override
  State<_ValueEditorDialog> createState() => _ValueEditorDialogState();
}

class _ValueEditorDialogState extends State<_ValueEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    final saved = await widget.onSave(_name.text);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.editor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyles.heading(fontSize: 19),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextFormField(
                  label: 'Name',
                  hintText: 'Enter a value name',
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'This field is required.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
