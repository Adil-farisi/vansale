import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:van_go/Vangoui/permissions/permission_provider.dart';

// Widget that shows child only if permission is granted
class PermissionWidget extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;
  final bool showLoader;

  const PermissionWidget({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.showLoader = true,
  });

  @override
  Widget build(BuildContext context) {
    final permissionProvider = context.watch<PermissionProvider>();

    // If still loading
    if (permissionProvider.isLoading && showLoader) {
      return const CircularProgressIndicator.adaptive();
    }

    // Check permission
    final hasPerm = permissionProvider.hasPermission(permission);

    if (hasPerm) {
      return child;
    } else if (fallback != null) {
      return fallback!;
    } else {
      return const SizedBox.shrink();
    }
  }
}

// Button that's enabled/disabled based on permission
class PermissionButton extends StatelessWidget {
  final String permission;
  final VoidCallback onPressed;
  final Widget child;
  final String? tooltipMessage;
  final bool showTooltipWhenDisabled;

  const PermissionButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.tooltipMessage,
    this.showTooltipWhenDisabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final permissionProvider = context.watch<PermissionProvider>();
    final hasPermission = permissionProvider.hasPermission(permission);

    Widget button = ElevatedButton(
      onPressed: hasPermission ? onPressed : null,
      child: child,
    );

    if (!hasPermission && showTooltipWhenDisabled) {
      return Tooltip(
        message: tooltipMessage ?? 'You do not have permission for this action',
        child: button,
      );
    }

    return button;
  }
}