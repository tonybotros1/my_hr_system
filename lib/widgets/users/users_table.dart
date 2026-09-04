import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/users/user_model.dart';

class UsersTable extends StatefulWidget {
  const UsersTable({
    required this.users,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    required this.isCurrentUser,
    required this.mutatingUserId,
    super.key,
  });

  final List<UserModel> users;
  final ValueChanged<UserModel> onEdit;
  final ValueChanged<UserModel> onDelete;
  final void Function(UserModel user, bool status) onStatusChanged;
  final bool Function(UserModel user) isCurrentUser;
  final String? mutatingUserId;

  @override
  State<UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<UsersTable> {
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight <= AppSizes.payrollTableHeaderHeight) {
          return const ColoredBox(color: AppColors.tableHeader);
        }
        final tableWidth = constraints.maxWidth > AppSizes.usersTableMinWidth
            ? constraints.maxWidth
            : AppSizes.usersTableMinWidth;
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  const _TableHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.users.length,
                      itemExtent: AppSizes.usersTableRowHeight,
                      itemBuilder: (context, index) {
                        final user = widget.users[index];
                        return _UserRow(
                          user: user,
                          isCurrentUser: widget.isCurrentUser(user),
                          isMutating: widget.mutatingUserId == user.id,
                          onEdit: () => widget.onEdit(user),
                          onDelete: () => widget.onDelete(user),
                          onStatusChanged: (status) =>
                              widget.onStatusChanged(user, status),
                        );
                      },
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

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.payrollTableHeaderHeight,
      color: AppColors.tableHeader,
      child: const Row(
        children: [
          _HeaderCell('Actions', width: 100),
          _HeaderCell('Name', flex: 3),
          _HeaderCell('Email', flex: 4),
          _HeaderCell('Expiry date', width: 135),
          _HeaderCell('HR screens', width: 105),
          _HeaderCell('Admin', width: 90),
          _HeaderCell('Status', width: 125),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.width, this.flex = 1});

  final String text;
  final double? width;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text.toUpperCase(), style: AppTextStyles.tableHeader),
      ),
    );
    return width == null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: width, child: child);
  }
}

class _UserRow extends StatefulWidget {
  const _UserRow({
    required this.user,
    required this.isCurrentUser,
    required this.isMutating,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final UserModel user;
  final bool isCurrentUser;
  final bool isMutating;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onStatusChanged;

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: _hovered ? AppColors.softSurface : AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RowAction(
                    tooltip: widget.isCurrentUser
                        ? 'You cannot delete your own account'
                        : 'Delete user',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    onPressed: widget.isCurrentUser || widget.isMutating
                        ? null
                        : widget.onDelete,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  _RowAction(
                    tooltip: 'Edit user',
                    icon: Icons.edit_outlined,
                    onPressed: widget.isMutating ? null : widget.onEdit,
                  ),
                ],
              ),
            ),
            _BodyCell(widget.user.userName, flex: 3, strong: true),
            _BodyCell(widget.user.email, flex: 4),
            _BodyCell(formatUserDate(widget.user.expiryDate), width: 135),
            _BodyCell(
              widget.user.hrScreenAccess == null
                  ? 'All'
                  : '${widget.user.hrScreenAccess!.length}',
              width: 105,
              strong: true,
            ),
            SizedBox(
              width: 90,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Badge(
                  label: widget.user.isAdmin ? 'Yes' : 'No',
                  active: widget.user.isAdmin,
                ),
              ),
            ),
            SizedBox(
              width: 125,
              child: Row(
                children: [
                  Switch(
                    value: widget.user.status,
                    onChanged: widget.isCurrentUser || widget.isMutating
                        ? null
                        : widget.onStatusChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    widget.user.status ? 'Active' : 'Inactive',
                    style: AppTextStyles.tableBody.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text, {this.width, this.flex = 1, this.strong = false});

  final String text;
  final double? width;
  final int flex;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.isEmpty ? '—' : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.tableBody.copyWith(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
    return width == null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: width, child: child);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(
          color: active ? AppColors.primaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 34,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: destructive
                ? AppColors.error
                : AppColors.primaryDark,
            disabledForegroundColor: AppColors.textHint,
            hoverColor: destructive
                ? AppColors.dangerBackground
                : AppColors.primaryLight,
            padding: EdgeInsets.zero,
          ),
          icon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
