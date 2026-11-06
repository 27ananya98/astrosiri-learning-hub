import 'package:flutter/material.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../domain/models/user.dart';

class CertificatePreviewSheet extends StatelessWidget {
  final String certificateTitle;
  final User user;
  final String issueDate;

  const CertificatePreviewSheet({
    super.key,
    required this.certificateTitle,
    required this.user,
    this.issueDate = '',
  });

  static void show(
    BuildContext context, {
    required String certificateTitle,
    required User user,
    String? issueDate,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertificatePreviewSheet(
          certificateTitle: certificateTitle,
          user: user,
          issueDate: issueDate ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipientName = user.fullName.isNotEmpty ? user.fullName : 'Learner';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Verified Certificate',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Ornate Ivory Certificate Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD97706), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Seal
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFEF3C7),
                    border: Border.all(
                      color: const Color(0xFFD97706),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFD97706),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'ASTROSIRI VEDIC ACADEMY',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'CERTIFICATE OF COMPLETION',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'This is proudly presented to',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 4),

                Text(
                  recipientName,
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  'for successfully completing the comprehensive curriculum in',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 4),

                Text(
                  certificateTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 12),

                // Signatures & Verification Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acharya Pankaj',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 1,
                          color: const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Dean of Vedic Studies',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF059669),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'VERIFIED #AS-${user.id.substring(0, 6).toUpperCase()}',
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Issued: $issueDate',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Share Credential',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    AppToast.info(
                      context,
                      'Sharing $certificateTitle credential...',
                      title: 'Share Credential',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Download PDF',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    AppToast.success(
                      context,
                      'Downloading official certificate for $recipientName...',
                      title: 'Download Started',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
