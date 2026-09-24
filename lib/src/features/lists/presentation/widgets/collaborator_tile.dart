import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/collaborator.dart';

class CollaboratorTile extends StatelessWidget {
  final Collaborator collaborator;
  final VoidCallback? onRemove;
  final ValueChanged<CollaboratorRole>? onRoleChanged;
  final String ownerLabel;
  final String adminLabel;
  final String memberLabel;
  final String removeTooltip;

  const CollaboratorTile({
    super.key,
    required this.collaborator,
    this.onRemove,
    this.onRoleChanged,
    this.ownerLabel = 'Dueño',
    this.adminLabel = 'Admin',
    this.memberLabel = 'Colaborador',
    this.removeTooltip = 'Quitar colaborador',
  });

  Widget _buildRoleBadge() {
    if (collaborator.isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          ownerLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      );
    }

    final isAdmin = collaborator.role == CollaboratorRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFF3E8FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAdmin ? adminLabel : memberLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAdmin
                  ? const Color(0xFF7E22CE)
                  : const Color(0xFF475569),
            ),
          ),
          if (onRoleChanged != null) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 14,
              color: isAdmin
                  ? const Color(0xFF7E22CE)
                  : const Color(0xFF475569),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              collaborator.initials,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collaborator.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  collaborator.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (collaborator.isOwner)
            _buildRoleBadge()
          else ...[
            if (onRoleChanged != null)
              PopupMenuButton<CollaboratorRole>(
                key: ValueKey('change_role_${collaborator.id}'),
                tooltip: 'Cambiar rol',
                initialValue: collaborator.role,
                onSelected: onRoleChanged,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: CollaboratorRole.admin,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          size: 16,
                          color: Color(0xFF7E22CE),
                        ),
                        const SizedBox(width: 8),
                        Text(adminLabel),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CollaboratorRole.member,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        Text(memberLabel),
                      ],
                    ),
                  ),
                ],
                child: _buildRoleBadge(),
              )
            else
              _buildRoleBadge(),
            if (onRemove != null)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                splashRadius: 18,
                onPressed: onRemove,
                tooltip: removeTooltip,
              ),
          ],
        ],
      ),
    );
  }
}
