import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

class LocationAccessDialog extends StatefulWidget {
  const LocationAccessDialog({
    required this.onAllow,
    required this.onSkip,
    super.key,
  });

  static const dialogKey = Key('location_access_dialog');
  static const allowButtonKey = Key('location_access_allow');
  static const skipButtonKey = Key('location_access_skip');

  final Future<void> Function() onAllow;
  final VoidCallback onSkip;

  @override
  State<LocationAccessDialog> createState() => _LocationAccessDialogState();
}

class _LocationAccessDialogState extends State<LocationAccessDialog> {
  var _requesting = false;

  Future<void> _allow() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await widget.onAllow();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось получить геолокацию. Можно выбрать адрес вручную.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        key: LocationAccessDialog.dialogKey,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'docs/imgs/geo.png',
                width: 90,
                height: 80,
                fit: BoxFit.fill,
              ),
              const SizedBox(height: 16),
              const Text(
                'Доступ к геолокации',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Разрешите доступ к геолокации — так будет проще найти подходящий вариант',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  key: LocationAccessDialog.allowButtonKey,
                  onPressed: _requesting ? null : _allow,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _requesting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentWhite,
                          ),
                        )
                      : const Text(
                          'Разрешить',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  key: LocationAccessDialog.skipButtonKey,
                  onPressed: _requesting ? null : widget.onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandGreen,
                    side: const BorderSide(color: AppColors.brandGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Пропустить',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
