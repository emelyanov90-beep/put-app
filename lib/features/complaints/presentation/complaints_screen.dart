import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/complaints/application/complaints_controller.dart';
import 'package:vput/features/complaints/domain/complaint.dart';
import 'package:vput/features/profile/presentation/widgets/profile_section_scaffold.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

/// «Жалобы»: what the user has reported and what the administrator answered.
class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({required this.onBack, super.key});

  static const createButtonKey = Key('complaints_create');
  static const textFieldKey = Key('complaint_text');
  static const submitButtonKey = Key('complaint_submit');

  static Key complaintKey(String id) => Key('complaint_$id');
  static Key subjectKey(ComplaintSubject subject) =>
      Key('complaint_subject_${subject.name}');

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(complaintsProvider)
        .when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(child: SystemLoadingView()),
          ),
          error: (_, _) => Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SystemFailureView(
                onRetry: () => ref.read(complaintsProvider.notifier).reload(),
              ),
            ),
          ),
          data: (complaints) => ProfileSectionScaffold(
            title: 'Жалобы',
            onBack: onBack,
            footer: ProfilePrimaryAction(
              actionKey: createButtonKey,
              label: 'Написать жалобу',
              onPressed: () => _openEditor(context, ref),
            ),
            children: [
              if (complaints.isEmpty)
                const ProfileEmptyState(
                  icon: Icons.report_outlined,
                  title: 'Жалоб пока нет',
                  description:
                      'Расскажите о проблеме с поездкой, оплатой или '
                      'приложением — администратор её разберёт.',
                )
              else
                for (var index = 0; index < complaints.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  _ComplaintCard(complaint: complaints[index]),
                ],
            ],
          ),
        );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<_ComplaintDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ComplaintEditor(),
    );
    if (draft == null) return;
    final failure = await ref
        .read(complaintsProvider.notifier)
        .submit(subject: draft.subject, text: draft.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(failure ?? 'Жалоба отправлена администратору.')),
      );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      key: ComplaintsScreen.complaintKey(complaint.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaintSubjectLabel(complaint.subject),
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
              ),
              Text(
                complaint.statusLabel,
                style: TextStyle(
                  color: complaint.status == ComplaintStatus.resolved
                      ? AppColors.brandGreen
                      : AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.text,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 15,
              height: 1.33,
            ),
          ),
          if (complaint.adminComment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ответ администратора: ${complaint.adminComment}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            RussianDateLabels.dateAndTime(complaint.createdAt),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintDraft {
  const _ComplaintDraft({required this.subject, required this.text});

  final ComplaintSubject subject;
  final String text;
}

class _ComplaintEditor extends StatefulWidget {
  const _ComplaintEditor();

  @override
  State<_ComplaintEditor> createState() => _ComplaintEditorState();
}

class _ComplaintEditorState extends State<_ComplaintEditor> {
  final _text = TextEditingController();
  var _subject = ComplaintSubject.trip;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSubmit => _text.text.trim().length >= complaintMinLength;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Новая жалоба',
                  style: TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                const ProfileSectionTitle('Тема'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final subject in ComplaintSubject.values)
                      ChoiceChip(
                        key: ComplaintsScreen.subjectKey(subject),
                        label: Text(complaintSubjectLabel(subject)),
                        selected: _subject == subject,
                        showCheckmark: false,
                        backgroundColor: AppColors.accentWhite,
                        selectedColor: AppColors.brandGreen,
                        labelStyle: TextStyle(
                          color: _subject == subject
                              ? AppColors.accentWhite
                              : AppColors.accentBlack,
                          fontSize: 13,
                          height: 1.38,
                        ),
                        side: BorderSide.none,
                        onSelected: (_) => setState(() => _subject = subject),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const ProfileSectionTitle('Что случилось'),
                ProfileCard(
                  child: TextField(
                    key: ComplaintsScreen.textFieldKey,
                    controller: _text,
                    maxLines: 5,
                    maxLength: complaintMaxLength,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 15,
                      height: 1.33,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText:
                          'Опишите проблему: что произошло, когда и с кем',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.33,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ProfilePrimaryAction(
                  actionKey: ComplaintsScreen.submitButtonKey,
                  label: 'Отправить',
                  onPressed: _canSubmit
                      ? () => Navigator.of(context).pop(
                          _ComplaintDraft(
                            subject: _subject,
                            text: _text.text.trim(),
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
