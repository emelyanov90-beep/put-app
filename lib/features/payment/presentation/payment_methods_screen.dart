import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/payment/application/payment_methods_controller.dart';
import 'package:vput/features/payment/domain/payment_method.dart';
import 'package:vput/features/profile/presentation/widgets/profile_section_scaffold.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

/// «Способ оплаты»: the cards used by the mock payment action.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({required this.onBack, super.key});

  static const addButtonKey = Key('payment_add');
  static const numberFieldKey = Key('payment_number');
  static const expiryFieldKey = Key('payment_expiry');
  static const saveButtonKey = Key('payment_save');

  static Key cardKey(String id) => Key('payment_card_$id');
  static Key removeKey(String id) => Key('payment_remove_$id');

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentMethodsProvider);
    final cards = state.value ?? const <PaymentMethod>[];

    return ProfileSectionScaffold(
      title: 'Способ оплаты',
      onBack: onBack,
      footer: ProfilePrimaryAction(
        actionKey: addButtonKey,
        label: 'Добавить карту',
        onPressed: () => _openEditor(context, ref),
      ),
      children: [
        if (state.isLoading)
          const SizedBox(height: 240, child: SystemLoadingView())
        else ...[
          if (cards.isEmpty)
            const ProfileEmptyState(
              icon: Icons.credit_card_rounded,
              title: 'Карт пока нет',
              description:
                  'Добавьте карту, чтобы оплачивать бронирования. В тестовой '
                  'версии деньги не списываются.',
            )
          else
            for (final card in cards) ...[
              _CardTile(
                card: card,
                onMakeDefault: () => ref
                    .read(paymentMethodsProvider.notifier)
                    .makeDefault(card.id),
                onRemove: () =>
                    ref.read(paymentMethodsProvider.notifier).remove(card.id),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 10),
          const Text(
            'Оплата выполняется в тестовом режиме: деньги не списываются, '
            'полный номер карты не сохраняется.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.38,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_CardDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CardEditor(),
    );
    if (result == null) return;
    await ref
        .read(paymentMethodsProvider.notifier)
        .add(number: result.number, expiry: result.expiry);
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.onMakeDefault,
    required this.onRemove,
  });

  final PaymentMethod card;
  final VoidCallback onMakeDefault;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      padded: false,
      child: InkWell(
        key: PaymentMethodsScreen.cardKey(card.id),
        onTap: card.isDefault ? null : onMakeDefault,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Icon(
                Icons.credit_card_rounded,
                size: 22,
                color: card.isDefault
                    ? AppColors.brandGreen
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${card.brandLabel} ${card.maskedNumber}',
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.isDefault
                          ? 'Основная карта · до ${card.expiry}'
                          : 'до ${card.expiry} · нажмите, чтобы сделать основной',
                      style: TextStyle(
                        color: card.isDefault
                            ? AppColors.brandGreen
                            : AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: PaymentMethodsScreen.removeKey(card.id),
                onPressed: onRemove,
                tooltip: 'Удалить карту',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDraft {
  const _CardDraft({required this.number, required this.expiry});

  final String number;
  final String expiry;
}

class _CardEditor extends StatefulWidget {
  const _CardEditor();

  @override
  State<_CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<_CardEditor> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    super.dispose();
  }

  bool get _canSave {
    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 16 &&
        RegExp(r'^\d{2}/\d{2}$').hasMatch(_expiry.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Новая карта',
                  style: TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                ProfileCard(
                  child: TextField(
                    key: PaymentMethodsScreen.numberFieldKey,
                    controller: _number,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 15,
                      height: 1.33,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Номер карты',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.33,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ProfileCard(
                  child: TextField(
                    key: PaymentMethodsScreen.expiryFieldKey,
                    controller: _expiry,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [LengthLimitingTextInputFormatter(5)],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 15,
                      height: 1.33,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Срок действия, ММ/ГГ',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.33,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Сохраняются только последние четыре цифры и срок действия.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 20),
                ProfilePrimaryAction(
                  actionKey: PaymentMethodsScreen.saveButtonKey,
                  label: 'Добавить',
                  onPressed: _canSave
                      ? () => Navigator.of(context).pop(
                          _CardDraft(
                            number: _number.text,
                            expiry: _expiry.text,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
