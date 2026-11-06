import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

Future<void> showLogoutConfirmation(
  BuildContext context, {
  bool closeDrawerAfterConfirmation = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFFFFFBF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFC7DDF5)),
      ),
      title: const Row(
        children: [
          Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
          SizedBox(width: 10),
          Text(
            'Confirm Log Out',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to log out from Astrosiri Learning Hub?',
        style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text(
            'Log Out',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final authCubit = context.read<AuthCubit>();
  if (closeDrawerAfterConfirmation) {
    Navigator.of(context).pop();
  }
  await authCubit.logout();
}
