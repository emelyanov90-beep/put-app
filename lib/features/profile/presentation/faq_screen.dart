import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/profile/presentation/widgets/profile_section_scaffold.dart';

/// One question and its answer.
class FaqEntry {
  const FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// The answers describe the rules the app actually enforces (commission,
/// standard vs instant booking, cancellations, parcels), so support copy and
/// behaviour cannot drift apart.
const faqEntries = <FaqEntry>[
  FaqEntry(
    question: 'Как забронировать место?',
    answer:
        'Откройте поездку, нажмите «Забронировать место» и выберите точки '
        'посадки и высадки, число пассажиров и нужные услуги. При стандартном '
        'бронировании заявку сначала подтверждает водитель, при быстром — '
        'оплата доступна сразу.',
  ),
  FaqEntry(
    question: 'Чем стандартное бронирование отличается от быстрого?',
    answer:
        'При стандартном водитель видит вашу заявку, может открыть профиль и '
        'подтвердить или отклонить её. При быстром подтверждение не нужно: '
        'место резервируется сразу после оплаты.',
  ),
  FaqEntry(
    question: 'За что списывается комиссия?',
    answer:
        'Комиссия платформы фиксированная и входит в стоимость поездки. '
        'Водитель получает сумму поездки за вычетом комиссии. В тестовой '
        'версии оплата выполняется без реального списания денег.',
  ),
  FaqEntry(
    question: 'Как отменить бронирование?',
    answer:
        'Откройте заказ в разделе «Мои заказы» и нажмите «Отменить '
        'бронирование». Если бронь была оплачена, заявка на возврат уходит '
        'администратору. После двух отмен за 30 дней новые бронирования '
        'временно недоступны.',
  ),
  FaqEntry(
    question: 'Как отправить посылку без поездки?',
    answer:
        'Выберите поездку, водитель которой возит посылки, и нажмите '
        '«Отправить посылку». Укажите, где её забрать и куда доставить, и '
        'выберите размер — стоимость размера задаёт платформа.',
  ),
  FaqEntry(
    question: 'Что нужно, чтобы публиковать поездки?',
    answer:
        'В профиле переключитесь на роль водителя и добавьте автомобиль в '
        'разделе «Транспортные средства». Публиковать поездки можно только на '
        'проверенном автомобиле — статус присваивает администратор после '
        'загрузки СТС.',
  ),
  FaqEntry(
    question: 'Почему поездку не видно в списке?',
    answer:
        'Пассажирам показываются только опубликованные поездки с открытым '
        'приёмом заявок и датой выезда в будущем. Если у водителя две '
        'одинаковые поездки, набор пассажиров идёт только в одну из них.',
  ),
  FaqEntry(
    question: 'Куда приходит код подтверждения?',
    answer:
        'В тестовой версии SMS не отправляются: код подтверждения для любого '
        'корректного номера — 111111.',
  ),
];

/// «Частые вопросы»: an accordion over [faqEntries].
class FaqScreen extends StatefulWidget {
  const FaqScreen({required this.onBack, super.key});

  static Key questionKey(int index) => Key('faq_question_$index');

  final VoidCallback onBack;

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _openIndex;

  @override
  Widget build(BuildContext context) {
    return ProfileSectionScaffold(
      title: 'Частые вопросы',
      onBack: widget.onBack,
      children: [
        for (var index = 0; index < faqEntries.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _FaqTile(
            tileKey: FaqScreen.questionKey(index),
            entry: faqEntries[index],
            expanded: _openIndex == index,
            onTap: () =>
                setState(() => _openIndex = _openIndex == index ? null : index),
          ),
        ],
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.tileKey,
    required this.entry,
    required this.expanded,
    required this.onTap,
  });

  final Key tileKey;
  final FaqEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      padded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: tileKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.question,
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                entry.answer,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
