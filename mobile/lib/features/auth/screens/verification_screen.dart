import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/roadmate_button.dart';
import '../../../core/widgets/roadmate_card.dart';

/// Identity verification upload screen (L2/L3 verification).
///
/// Riders upload government ID and a selfie to raise their
/// trust / verification level.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _picker = ImagePicker();
  XFile? _idPhoto;
  XFile? _selfiePhoto;
  bool _isSubmitting = false;

  Future<void> _pickId() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _idPhoto = file);
  }

  Future<void> _takeSelfie() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) setState(() => _selfiePhoto = file);
  }

  Future<void> _submit() async {
    if (_idPhoto == null || _selfiePhoto == null) return;
    setState(() => _isSubmitting = true);

    // TODO(backend): Upload photos for verification.
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Documents submitted for review!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Increase your trust score by verifying your identity.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // ── Government ID ────────────────────────────────
              _UploadTile(
                label: 'Government ID',
                description: 'Aadhaar, PAN, or Driving Licence',
                icon: Icons.badge_outlined,
                fileName: _idPhoto?.name,
                onTap: _pickId,
              ),
              const SizedBox(height: 16),

              // ── Selfie ───────────────────────────────────────
              _UploadTile(
                label: 'Selfie',
                description: 'Clear photo of your face',
                icon: Icons.camera_alt_outlined,
                fileName: _selfiePhoto?.name,
                onTap: _takeSelfie,
              ),
              const SizedBox(height: 32),

              RoadmateButton(
                label: 'Submit for Verification',
                onPressed:
                    (_idPhoto != null && _selfiePhoto != null) ? _submit : null,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final String? fileName;
  final VoidCallback onTap;

  const _UploadTile({
    required this.label,
    required this.description,
    required this.icon,
    this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RoadmateCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              fileName != null ? Icons.check_circle : icon,
              color: fileName != null ? AppColors.statusGreen : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  fileName ?? description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.upload_outlined, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
