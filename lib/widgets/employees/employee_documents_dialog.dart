import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/employee_controllers/employees_controller.dart';
import '../../models/employees/employee_model.dart';
import '../../services/browser_dialog_history.dart';
import '../../services/external_url_opener.dart';
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
                : Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _showAttachmentFilesDialog(context, record!),
                      style: AppButtonStyles.tableOpen,
                      icon: const Icon(Icons.folder_open_outlined, size: 16),
                      label: const Text('Open'),
                    ),
                  ),
            1,
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

Future<void> _showAttachmentFilesDialog(
  BuildContext context,
  EmployeeAttachment attachment,
) async {
  final screen = MediaQuery.sizeOf(context);
  final availableWidth = math.max(280, screen.width - (AppSpacing.md * 2));
  final availableHeight = math.max(300, screen.height - (AppSpacing.md * 2));
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
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppColors.mainCanvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.editor),
        ),
        child: SizedBox(
          width: math
              .min(AppSizes.employeeAttachmentFilesDialogWidth, availableWidth)
              .toDouble(),
          height: math
              .min(
                AppSizes.employeeAttachmentFilesDialogHeight,
                availableHeight,
              )
              .toDouble(),
          child: _AttachmentFilesBody(attachment: attachment),
        ),
      ),
    );
  } finally {
    history.complete();
  }
}

class _AttachmentFilesBody extends StatelessWidget {
  const _AttachmentFilesBody({required this.attachment});

  final EmployeeAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final images = attachment.files
        .where(_isImageAttachmentFile)
        .toList(growable: false);
    final otherFiles = attachment.files
        .where((file) => !_isImageAttachmentFile(file))
        .toList(growable: false);

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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Files',
                      style: AppTextStyles.heading(
                        fontSize: 19,
                      ).copyWith(color: Colors.white),
                    ),
                    if (attachment.name.trim().isNotEmpty)
                      Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close files',
                onPressed: () => Navigator.of(context).pop<void>(),
                color: Colors.white,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: attachment.files.isEmpty
                ? Center(
                    child: Text(
                      'No files found.',
                      style: AppTextStyles.listCount,
                    ),
                  )
                : ListView(
                    children: [
                      _AttachmentFileSection(
                        title: 'Images',
                        emptyText: 'No images',
                        files: images,
                        showImagePreview: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _AttachmentFileSection(
                        title: 'Other Files',
                        emptyText: 'No other files',
                        files: otherFiles,
                        showImagePreview: false,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentFileSection extends StatelessWidget {
  const _AttachmentFileSection({
    required this.title,
    required this.emptyText,
    required this.files,
    required this.showImagePreview,
  });

  final String title;
  final String emptyText;
  final List<EmployeeAttachmentFile> files;
  final bool showImagePreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        if (files.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
            child: Text(emptyText, style: AppTextStyles.listCount),
          )
        else
          ...files.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AttachmentFileRow(
                file: file,
                showImagePreview: showImagePreview,
              ),
            ),
          ),
      ],
    );
  }
}

class _AttachmentFileRow extends StatelessWidget {
  const _AttachmentFileRow({
    required this.file,
    required this.showImagePreview,
  });

  final EmployeeAttachmentFile file;
  final bool showImagePreview;

  @override
  Widget build(BuildContext context) {
    final displayName = file.name.trim().isEmpty ? 'Attachment' : file.name;
    final detail = _attachmentFileDetail(file);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openAttachmentFile(context, file),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              _AttachmentFilePreview(
                file: file,
                showImagePreview: showImagePreview,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tableBody.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(detail, style: AppTextStyles.listCount),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Open file',
                onPressed: () => _openAttachmentFile(context, file),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primaryDark,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentFilePreview extends StatelessWidget {
  const _AttachmentFilePreview({
    required this.file,
    required this.showImagePreview,
  });

  final EmployeeAttachmentFile file;
  final bool showImagePreview;

  @override
  Widget build(BuildContext context) {
    if (!showImagePreview || file.url.trim().isEmpty) {
      return _fileTypePreview(file);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.navigationItem),
      child: Image.network(
        file.url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fileTypePreview(file),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            color: AppColors.primaryLight,
            child: const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}

Widget _fileTypePreview(EmployeeAttachmentFile file) {
  return Container(
    width: 56,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppRadii.navigationItem),
    ),
    child: Icon(
      _attachmentFileIcon(file),
      color: AppColors.primaryDark,
      size: 28,
    ),
  );
}

bool _isImageAttachmentFile(EmployeeAttachmentFile file) {
  if (file.resourceType.toLowerCase() == 'image') return true;
  const imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tif',
    'tiff',
    'svg',
  };
  return imageExtensions.contains(_attachmentFileExtension(file));
}

String _attachmentFileExtension(EmployeeAttachmentFile file) {
  final format = file.format.trim().toLowerCase();
  if (format.isNotEmpty) return format;
  final cleanName = file.name.split('?').first;
  final dot = cleanName.lastIndexOf('.');
  if (dot < 0 || dot == cleanName.length - 1) return '';
  return cleanName.substring(dot + 1).toLowerCase();
}

String _attachmentFileDetail(EmployeeAttachmentFile file) {
  final extension = _attachmentFileExtension(file);
  if (extension.isNotEmpty) return '${extension.toUpperCase()} file';
  final resourceType = file.resourceType.trim();
  return resourceType.isEmpty ? '' : resourceType;
}

IconData _attachmentFileIcon(EmployeeAttachmentFile file) {
  return switch (_attachmentFileExtension(file)) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' => Icons.description_outlined,
    'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
    'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

Future<void> _openAttachmentFile(
  BuildContext context,
  EmployeeAttachmentFile file,
) async {
  if (file.url.trim().isEmpty) {
    await showAppAlertDialog(
      title: 'File unavailable',
      message: 'This file does not have a valid link.',
      kind: AppAlertKind.error,
    );
    return;
  }
  openExternalUrl(file.url);
}

Future<void> _showAttachmentEditor(BuildContext context) async {
  final screen = MediaQuery.sizeOf(context);
  final availableWidth = math.max(280, screen.width - (AppSpacing.md * 2));
  final availableHeight = math.max(360, screen.height - (AppSpacing.md * 2));
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
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppColors.mainCanvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.editor),
        ),
        child: SizedBox(
          key: const ValueKey('employee-attachment-editor-dialog-content'),
          width: math
              .min(AppSizes.employeeAttachmentEditorDialogWidth, availableWidth)
              .toDouble(),
          height: math
              .min(
                AppSizes.employeeAttachmentEditorDialogHeight,
                availableHeight,
              )
              .toDouble(),
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
                'New Record',
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
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(builder: _buildEditorLayout),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorLayout(BuildContext context, BoxConstraints constraints) {
    final compact =
        constraints.maxWidth <
        AppSizes.employeeAttachmentEditorTwoColumnBreakpoint;
    if (compact) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _attachmentDetailsFields(),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(height: 420, child: _attachmentPickerPanel()),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: SingleChildScrollView(child: _attachmentDetailsFields()),
        ),
        const SizedBox(width: AppSpacing.lg),
        const VerticalDivider(width: 1, color: AppColors.divider),
        const SizedBox(width: AppSpacing.lg),
        Expanded(flex: 9, child: _attachmentPickerPanel()),
      ],
    );
  }

  Widget _attachmentDetailsFields() => Column(
    key: const ValueKey('employee-attachment-details-column'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Record Details', style: AppTextStyles.sectionTitle),
      const SizedBox(height: AppSpacing.md),
      AppTextFormField(
        label: 'Name',
        hintText: 'Document name',
        controller: _name,
        validator: controller.requiredText,
      ),
      const SizedBox(height: AppSpacing.md),
      _fieldRow(
        _typeDropdown(),
        AppTextFormField(
          label: 'Number',
          hintText: 'Document number',
          controller: _number,
          validator: controller.requiredText,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _fieldRow(
        _dateField('Start Date', _startDate),
        _dateField('End Date', _endDate),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextFormField(
        key: const ValueKey('employee-attachment-notes-field'),
        label: 'Notes',
        hintText: 'Optional notes',
        controller: _note,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: 10,
        maxLines: 10,
      ),
    ],
  );

  Widget _fieldRow(Widget left, Widget right) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: right),
    ],
  );

  Widget _attachmentPickerPanel() => Container(
    key: const ValueKey('employee-attachment-upload-column'),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: AppDecorations.contentCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.attach_file_rounded,
              color: AppColors.primaryDark,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Attachments *',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle,
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 28),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadii.navigationItem),
              ),
              child: Text('${_files.length}', style: AppTextStyles.listCount),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: AppColors.primaryLight,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(AppRadii.field),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _pickFiles,
            child: SizedBox(
              height: 124,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.primaryDark,
                    size: 34,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Choose files', style: AppTextStyles.link),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Images, PDFs and documents • Max '
                    '${AppLimits.employeeAttachmentMaxFileSizeMb} MB each',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.listCount,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _files.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.softSurface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.folder_open_outlined,
                        color: AppColors.textHint,
                        size: 34,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('No files selected', style: AppTextStyles.listCount),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _files.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final entry = _files.entries.elementAt(index);
                    return _PickedAttachmentTile(
                      name: entry.key,
                      bytes: entry.value,
                      onRemove: () => setState(
                        () => _files = Map.of(_files)..remove(entry.key),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );

  Widget _typeDropdown() => LayoutBuilder(
    builder: (context, constraints) => CustomDropdown(
      width: constraints.maxWidth,
      hintText: 'Type',
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
    if (!mounted || files.isEmpty) return;

    final oversized = files.entries
        .where(
          (entry) =>
              entry.value.length > AppLimits.employeeAttachmentMaxFileBytes,
        )
        .toList(growable: false);
    final accepted = Map<String, List<int>>.fromEntries(
      files.entries.where(
        (entry) =>
            entry.value.length <= AppLimits.employeeAttachmentMaxFileBytes,
      ),
    );

    if (accepted.isNotEmpty) {
      setState(() => _files = {..._files, ...accepted});
    }
    if (oversized.isNotEmpty) {
      final names = oversized.map((entry) => entry.key).join(', ');
      await showAppAlertDialog(
        title: 'File too large',
        message:
            'Each attachment must be '
            '${AppLimits.employeeAttachmentMaxFileSizeMb} MB or smaller. '
            'The following file${oversized.length == 1 ? '' : 's'} '
            '${oversized.length == 1 ? 'was' : 'were'} not added: $names',
        kind: AppAlertKind.error,
      );
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

class _PickedAttachmentTile extends StatelessWidget {
  const _PickedAttachmentTile({
    required this.name,
    required this.bytes,
    required this.onRemove,
  });

  final String name;
  final List<int> bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            _PickedAttachmentPreview(name: name, bytes: bytes),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.tableBody.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _pickedAttachmentDetail(name, bytes.length),
                    style: AppTextStyles.listCount,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove $name',
              onPressed: onRemove,
              color: AppColors.error,
              icon: const Icon(Icons.delete_outline, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedAttachmentPreview extends StatelessWidget {
  const _PickedAttachmentPreview({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;

  @override
  Widget build(BuildContext context) {
    if (!_isPickedAttachmentImage(name)) {
      return _pickedAttachmentIcon(name);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.navigationItem),
      child: Image.memory(
        Uint8List.fromList(bytes),
        width: AppSizes.employeeAttachmentPickerPreviewSize,
        height: AppSizes.employeeAttachmentPickerPreviewSize,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _pickedAttachmentIcon(name),
      ),
    );
  }
}

Widget _pickedAttachmentIcon(String name) => Container(
  width: AppSizes.employeeAttachmentPickerPreviewSize,
  height: AppSizes.employeeAttachmentPickerPreviewSize,
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(AppRadii.navigationItem),
  ),
  child: Icon(
    _pickedAttachmentFileIcon(name),
    color: AppColors.primaryDark,
    size: 27,
  ),
);

String _pickedAttachmentExtension(String name) {
  final cleanName = name.split('?').first;
  final dot = cleanName.lastIndexOf('.');
  if (dot < 0 || dot == cleanName.length - 1) return '';
  return cleanName.substring(dot + 1).toLowerCase();
}

bool _isPickedAttachmentImage(String name) => const {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'bmp',
  'webp',
  'heic',
  'heif',
  'tif',
  'tiff',
}.contains(_pickedAttachmentExtension(name));

IconData _pickedAttachmentFileIcon(String name) {
  return switch (_pickedAttachmentExtension(name)) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' => Icons.description_outlined,
    'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
    'ppt' || 'pptx' => Icons.slideshow_outlined,
    'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
    'mp3' || 'wav' || 'm4a' => Icons.audio_file_outlined,
    'mp4' || 'mov' || 'avi' => Icons.video_file_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

String _pickedAttachmentDetail(String name, int byteCount) {
  final extension = _pickedAttachmentExtension(name);
  final size = byteCount < 1024
      ? '$byteCount B'
      : byteCount < 1024 * 1024
      ? '${(byteCount / 1024).toStringAsFixed(1)} KB'
      : '${(byteCount / (1024 * 1024)).toStringAsFixed(1)} MB';
  return extension.isEmpty ? size : '${extension.toUpperCase()} • $size';
}
