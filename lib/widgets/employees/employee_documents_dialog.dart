import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web/web.dart' as web;

import '../../consts.dart';
import '../../controllers/employee_controllers/employees_controller.dart';
import '../../models/employees/employee_model.dart';
import '../../services/browser_dialog_history.dart';
import '../dialogs/app_alert_dialog.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_date_form_field.dart';
import '../form_fields/app_text_form_field.dart';

Future<void> showEmployeeDocumentsDialog(BuildContext context) async {
  final controller = Get.find<EmployeesController>();
  await controller.loadAttachments();
  if (!context.mounted) return;
  final screen = MediaQuery.sizeOf(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final history = BrowserDialogHistory.open(() {
    if (navigator.canPop()) navigator.pop<void>();
  });
  try {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: AppColors.dialogScrim,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xs),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.editor),
        ),
        child: SizedBox(
          width: math.max(280, screen.width - (AppSpacing.md * 2)),
          height: math.max(360, screen.height - (AppSpacing.md * 2)),
          child: const _EmployeeDocumentsBody(),
        ),
      ),
    );
  } finally {
    history.complete();
  }
}

class _EmployeeDocumentsBody extends StatefulWidget {
  const _EmployeeDocumentsBody();

  @override
  State<_EmployeeDocumentsBody> createState() => _EmployeeDocumentsBodyState();
}

class _EmployeeDocumentsBodyState extends State<_EmployeeDocumentsBody> {
  final _search = TextEditingController();
  final _horizontal = ScrollController();

  EmployeesController get controller => Get.find<EmployeesController>();

  @override
  void dispose() {
    _search.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          color: AppColors.primaryDark,
          child: Row(
            children: [
              const Icon(Icons.folder_copy_outlined, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Document of Record',
                style: AppTextStyles.heading(
                  fontSize: 19,
                ).copyWith(color: Colors.white),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAttachmentEditor(context),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Record'),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop<void>(),
                color: Colors.white,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.mainCanvas,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                AppTextFormField(
                  label: 'Search',
                  hintText: 'Search attachments',
                  controller: _search,
                  onFieldSubmitted: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: DecoratedBox(
                    decoration: AppDecorations.contentCard,
                    child: Obx(() {
                      if (controller.isLoadingAttachments.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final query = _search.text.trim().toLowerCase();
                      final records = controller.attachments
                          .where((record) => _matches(record, query))
                          .toList(growable: false);
                      return _AttachmentTable(
                        records: records,
                        horizontalController: _horizontal,
                        onDelete: _delete,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _matches(EmployeeAttachment record, String query) {
    if (query.isEmpty) return true;
    return [
      record.name,
      record.typeName,
      record.number,
      record.note,
      ...record.files.map((file) => file.name),
    ].any((value) => value.toLowerCase().contains(query));
  }

  Future<void> _delete(EmployeeAttachment attachment) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete attachment?',
      message:
          '${attachment.name} and its uploaded files will be permanently removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteAttachment(attachment);
  }
}

class _AttachmentTable extends StatelessWidget {
  const _AttachmentTable({
    required this.records,
    required this.horizontalController,
    required this.onDelete,
  });

  final List<EmployeeAttachment> records;
  final ScrollController horizontalController;
  final ValueChanged<EmployeeAttachment> onDelete;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Text('No attachments found.', style: AppTextStyles.listCount),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(1040, constraints.maxWidth).toDouble();
        return Scrollbar(
          controller: horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  const _AttachmentRow(header: true),
                  Expanded(
                    child: ListView.builder(
                      itemCount: records.length,
                      itemExtent: 58,
                      itemBuilder: (context, index) => _AttachmentRow(
                        attachment: records[index],
                        onDelete: () => onDelete(records[index]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({this.attachment, this.onDelete, this.header = false});

  final EmployeeAttachment? attachment;
  final VoidCallback? onDelete;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final record = attachment;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: header ? AppColors.tableHeader : AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _cell(
            header
                ? 'ACTIONS'
                : IconButton(
                    tooltip: 'Delete attachment',
                    onPressed: onDelete,
                    color: AppColors.error,
                    icon: const Icon(Icons.delete_outline, size: 19),
                  ),
            1,
          ),
          _cell(header ? 'TYPE' : record!.typeName, 2),
          _cell(header ? 'NAME' : record!.name, 2),
          _cell(header ? 'NUMBER' : record!.number, 1),
          _cell(
            header
                ? 'START DATE'
                : EmployeesController.formatDate(record!.startDate),
            1,
          ),
          _cell(
            header
                ? 'END DATE'
                : EmployeesController.formatDate(record!.endDate),
            1,
          ),
          _cell(header ? 'NOTE' : record!.note, 2),
          _cell(
            header
                ? 'FILES'
                : Wrap(
                    spacing: AppSpacing.xs,
                    children: record!.files
                        .map(
                          (file) => TextButton(
                            onPressed: file.url.isEmpty
                                ? null
                                : () => web.window.open(file.url, '_blank'),
                            child: Text(
                              file.name.isEmpty ? 'Open' : file.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
            2,
          ),
        ],
      ),
    );
  }

  Widget _cell(Object value, int flex) => Expanded(
    flex: flex,
    child: value is Widget
        ? value
        : Text(
            value.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: header ? AppTextStyles.tableHeader : AppTextStyles.tableBody,
          ),
  );
}

Future<void> _showAttachmentEditor(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final history = BrowserDialogHistory.open(() {
    if (navigator.canPop()) navigator.pop<void>();
  });
  try {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: AppColors.dialogScrim,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 650),
          child: const _AttachmentEditor(),
        ),
      ),
    );
  } finally {
    history.complete();
  }
}

class _AttachmentEditor extends StatefulWidget {
  const _AttachmentEditor();

  @override
  State<_AttachmentEditor> createState() => _AttachmentEditorState();
}

class _AttachmentEditorState extends State<_AttachmentEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _type = TextEditingController();
  final _number = TextEditingController();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _note = TextEditingController();
  String _typeId = '';
  Map<String, List<int>> _files = {};

  EmployeesController get controller => Get.find<EmployeesController>();

  @override
  void dispose() {
    for (final field in [_name, _type, _number, _startDate, _endDate, _note]) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          color: AppColors.primaryDark,
          child: Row(
            children: [
              Text(
                'New Attachment',
                style: AppTextStyles.heading(
                  fontSize: 19,
                ).copyWith(color: Colors.white),
              ),
              const Spacer(),
              Obx(
                () => TextButton(
                  onPressed: controller.isSavingAttachment.value ? null : _save,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: controller.isSavingAttachment.value
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop<void>(),
                color: Colors.white,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 650;
                  final fields = [
                    AppTextFormField(
                      label: 'Name',
                      hintText: 'Document name',
                      controller: _name,
                      validator: controller.requiredText,
                    ),
                    _typeDropdown(),
                    AppTextFormField(
                      label: 'Number',
                      hintText: 'Document number',
                      controller: _number,
                      validator: controller.requiredText,
                    ),
                    _dateField('Start Date', _startDate),
                    _dateField('End Date', _endDate),
                    AppTextFormField(
                      label: 'Notes',
                      hintText: 'Optional notes',
                      controller: _note,
                      maxLines: 4,
                    ),
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (compact)
                        ...fields.expand(
                          (field) => [
                            field,
                            const SizedBox(height: AppSpacing.md),
                          ],
                        )
                      else
                        for (var i = 0; i < fields.length; i += 2) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: fields[i]),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: i + 1 < fields.length
                                    ? fields[i + 1]
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      OutlinedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          _files.isEmpty
                              ? 'Choose files'
                              : '${_files.length} file(s) selected',
                        ),
                      ),
                      if (_files.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: _files.keys
                              .map(
                                (name) => InputChip(
                                  label: Text(name),
                                  onDeleted: () => setState(
                                    () => _files = Map.of(_files)..remove(name),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeDropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          left: AppSizes.labelLeftPadding,
          bottom: AppSpacing.xs,
        ),
        child: Text('Type *', style: AppTextStyles.fieldLabel),
      ),
      LayoutBuilder(
        builder: (context, constraints) => CustomDropdown(
          width: constraints.maxWidth,
          hintText: 'Attachment type',
          textcontroller: _type.text,
          showedSelectedName: 'name',
          validator: true,
          onOpen: controller.attachmentTypes,
          onDelete: () => setState(() {
            _typeId = '';
            _type.clear();
          }),
          onChanged: (key, value) {
            final item = Map<String, dynamic>.from(value as Map);
            setState(() {
              _typeId = key;
              _type.text = employeeString(item['name']);
            });
          },
        ),
      ),
    ],
  );

  Widget _dateField(String label, TextEditingController field) =>
      AppDateFormField(
        label: label,
        controller: field,
        firstDate: DateTime(1940),
        lastDate: DateTime(2200),
      );

  Future<void> _pickFiles() async {
    final files = await controller.pickAttachmentFiles();
    if (files.isNotEmpty && mounted) {
      setState(() => _files = {..._files, ...files});
    }
  }

  Future<void> _save() async {
    if (_form.currentState?.validate() != true) return;
    if (_typeId.isEmpty || _files.isEmpty) {
      await showAppAlertDialog(
        title: 'Complete required fields',
        message: 'Select an attachment type and at least one file.',
        kind: AppAlertKind.error,
      );
      return;
    }
    final saved = await controller.addAttachment(
      name: _name.text,
      typeId: _typeId,
      number: _number.text,
      startDate: _startDate.text,
      endDate: _endDate.text,
      note: _note.text,
      files: _files,
    );
    if (saved && mounted) Navigator.of(context).pop();
  }
}
