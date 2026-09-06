import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/profile/data/device_profile_image_repository.dart';
import 'package:vput/features/profile/presentation/widgets/photo_source_sheet.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:vput/features/vehicles/data/preview_vehicle_catalog.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/presentation/widgets/vehicle_catalog_sheet.dart';

/// «Добавление нового ТС»: brand and model come from the catalogue, the driver
/// adds the seat count, a photo, the kind of vehicle and its documents.
class DriverVehicleFormScreen extends ConsumerStatefulWidget {
  const DriverVehicleFormScreen({
    required this.onBack,
    required this.onSaved,
    this.vehicleId,
    super.key,
  });

  static const brandFieldKey = Key('vehicle_form_brand');
  static const modelFieldKey = Key('vehicle_form_model');
  static const capacityFieldKey = Key('vehicle_form_capacity');
  static const photoButtonKey = Key('vehicle_form_photo');
  static const photoRemoveKey = Key('vehicle_form_photo_remove');
  static const typeCarKey = Key('vehicle_form_type_car');
  static const typeBusKey = Key('vehicle_form_type_bus');
  static const documentButtonKey = Key('vehicle_form_document');
  static const saveButtonKey = Key('vehicle_form_save');

  /// `null` adds a new vehicle.
  final String? vehicleId;
  final VoidCallback onBack;
  final ValueChanged<String> onSaved;

  @override
  ConsumerState<DriverVehicleFormScreen> createState() =>
      _DriverVehicleFormScreenState();
}

class _DriverVehicleFormScreenState
    extends ConsumerState<DriverVehicleFormScreen> {
  late final DriverVehicle? _existing = widget.vehicleId == null
      ? null
      : ref.read(driverVehiclesProvider.notifier).findById(widget.vehicleId!);

  late String? _brand = _existing?.brand;
  late String? _model = _existing?.model;
  late VehicleTransportType? _type = _existing?.transportType;
  late bool _hasDocument = _existing?.hasRegistrationDocument ?? false;
  late Uint8List? _documentBytes = _existing?.registrationDocumentBytes;
  bool _isPicking = false;
  bool _saving = false;
  late String? _photoAsset = _existing?.photoAsset;
  late Uint8List? _photoBytes = _existing?.photoBytes;
  late final _capacity = TextEditingController(
    text: _existing == null ? '' : _existing.seatCount.toString(),
  );

  @override
  void dispose() {
    _capacity.dispose();
    super.dispose();
  }

  bool get _hasPhoto => _photoBytes != null || _photoAsset != null;

  int get _seatCount => int.tryParse(_capacity.text.trim()) ?? 0;

  bool get _isValid =>
      _brand != null && _model != null && _seatCount > 0 && _type != null;

  Future<void> _pickBrand() async {
    final brand = await VehicleCatalogSheet.show(
      context,
      title: 'Выбрать марку автомобиля',
      options: previewVehicleBrands,
      grouped: true,
      selected: _brand,
    );
    if (brand == null || !mounted) return;
    final changed = brand != _brand;
    setState(() {
      _brand = brand;
      // Models belong to a brand, so the old one no longer applies.
      if (changed) _model = null;
    });
  }

  Future<void> _pickModel() async {
    final brand = _brand;
    if (brand == null) return;
    final model = await VehicleCatalogSheet.show(
      context,
      title: 'Выбрать модель $brand',
      options: previewVehicleModels(brand),
      selected: _model,
    );
    if (model == null || !mounted) return;
    setState(() => _model = model);
  }

  Future<void> _pickPhoto() => _pickImage(document: false);
  Future<void> _addDocument() => _pickImage(document: true);

  Future<void> _pickImage({required bool document}) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final source = await PhotoSourceSheet.show(context);
      if (source == null || !mounted) return;
      final bytes = await ref.read(profileImageRepositoryProvider).pick(source);
      if (bytes == null || !mounted) return;
      setState(() {
        if (document) {
          _documentBytes = bytes;
          _hasDocument = true;
        } else {
          _photoBytes = bytes;
          _photoAsset = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            document
                ? 'Не удалось выбрать СТС. Попробуйте ещё раз.'
                : 'Не удалось загрузить фотографию. Попробуйте ещё раз.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _save() async {
    if (!_isValid || _isPicking || _saving) return;
    _saving = true;
    final controller = ref.read(driverVehiclesProvider.notifier);
    final existing = _existing;

    if (existing == null) {
      final id = await controller.add(
        DriverVehicle(
          id: 'new',
          brand: _brand!,
          model: _model!,
          seatCount: _seatCount,
          verificationStatus: VehicleVerificationStatus.draft,
          transportType: _type!,
          photoAsset: _photoAsset,
          photoBytes: _photoBytes,
          hasRegistrationDocument: _hasDocument,
          registrationDocumentBytes: _documentBytes,
        ),
      );
      if (mounted) widget.onSaved(id);
      return;
    }

    await controller.update(
      existing.copyWith(
        brand: _brand,
        model: _model,
        seatCount: _seatCount,
        transportType: _type,
        photoAsset: _photoAsset,
        photoBytes: _photoBytes,
        hasRegistrationDocument: _hasDocument,
        registrationDocumentBytes: _documentBytes,
        clearPhoto: !_hasPhoto,
        verificationStatus: _hasDocument
            ? VehicleVerificationStatus.pending
            : VehicleVerificationStatus.draft,
      ),
    );
    if (mounted) widget.onSaved(existing.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ScreenHeader(
                title: _existing == null
                    ? 'Добавление нового ТС'
                    : 'Редактирование ТС',
                onBack: widget.onBack,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      title: 'Информация об автомобиле',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PickerField(
                            fieldKey: DriverVehicleFormScreen.brandFieldKey,
                            label: 'Марка',
                            value: _brand,
                            onTap: _pickBrand,
                          ),
                          _PickerField(
                            fieldKey: DriverVehicleFormScreen.modelFieldKey,
                            label: 'Модель',
                            value: _model,
                            onTap: _brand == null ? null : _pickModel,
                          ),
                          // The seat count is asked once the car itself is
                          // known, as in the design.
                          if (_brand != null)
                            _CapacityField(
                              controller: _capacity,
                              onChanged: (_) => setState(() {}),
                            ),
                          const SizedBox(height: 12),
                          if (_hasPhoto)
                            _PhotoPreview(
                              bytes: _photoBytes,
                              asset: _photoAsset,
                              onRemove: () => setState(() {
                                _photoBytes = null;
                                _photoAsset = null;
                              }),
                            )
                          else
                            _AddPhotoButton(onPressed: _pickPhoto),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Тип',
                      padded: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: _TypeCard(
                              cardKey: DriverVehicleFormScreen.typeCarKey,
                              icon: Icons.directions_car_filled_rounded,
                              label: 'Легковой',
                              selected: _type == VehicleTransportType.car,
                              onTap: () => setState(
                                () => _type = VehicleTransportType.car,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeCard(
                              cardKey: DriverVehicleFormScreen.typeBusKey,
                              icon: Icons.directions_bus_filled_rounded,
                              label: 'Автобус',
                              selected: _type == VehicleTransportType.bus,
                              onTap: () => setState(
                                () => _type = VehicleTransportType.bus,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Подтверждающие документы',
                      padded: false,
                      child: _DocumentButton(
                        hasDocument: _hasDocument,
                        onPressed: _addDocument,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  key: DriverVehicleFormScreen.saveButtonKey,
                  onPressed: _isValid && !_isPicking && !_saving ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: AppColors.accentWhite,
                    disabledBackgroundColor: AppColors.background,
                    disabledForegroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: _isValid
                          ? AppColors.brandGreen
                          : AppColors.divider,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(_existing == null ? 'Добавить' : 'Сохранить'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.padded = true,
  });

  final String title;
  final Widget child;

  /// `false` lets the content lay out its own cards, as the type row does.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.33,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: padded
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: child,
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

/// A row that opens a catalogue sheet: the label lifts once a value is chosen.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = value;
    return InkWell(
      key: fieldKey,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (chosen == null)
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.33,
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 16,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.33,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: Text(
                        chosen,
                        style: const TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 15,
                          height: 1.33,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: onTap == null ? AppColors.divider : AppColors.accentBlack,
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityField extends StatelessWidget {
  const _CapacityField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: DriverVehicleFormScreen.capacityFieldKey,
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              cursorColor: AppColors.accentBlack,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                height: 1.33,
              ),
              decoration: const InputDecoration(
                labelText: 'Вместимость',
                labelStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                floatingLabelStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const Text(
            'мест',
            style: TextStyle(
              color: AppColors.accentBlack,
              fontSize: 13,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        key: DriverVehicleFormScreen.photoButtonKey,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AppColors.brandGreen,
          side: const BorderSide(color: AppColors.brandGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        icon: const Icon(Icons.add_rounded, size: 14),
        label: const Text('Добавить фото'),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.bytes,
    required this.asset,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String? asset;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final photoBytes = bytes;
    final photoAsset = asset;
    return SizedBox(
      height: 175,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: photoBytes != null
                ? Image.memory(
                    photoBytes,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  )
                : Image.asset(
                    photoAsset!,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
          ),
          Center(
            child: SizedBox.square(
              dimension: 24,
              child: IconButton.filled(
                key: DriverVehicleFormScreen.photoRemoveKey,
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                tooltip: 'Удалить фото',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accentWhite.withValues(alpha: .5),
                  foregroundColor: AppColors.accentBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.cardKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key cardKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: cardKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandGreen.withValues(alpha: .12)
                : AppColors.accentWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brandGreen : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: AppColors.accentBlack),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentButton extends StatelessWidget {
  const _DocumentButton({required this.hasDocument, required this.onPressed});

  final bool hasDocument;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        key: DriverVehicleFormScreen.documentButtonKey,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: hasDocument
              ? AppColors.brandGreen
              : AppColors.textSecondary,
          side: BorderSide(
            color: hasDocument ? AppColors.brandGreen : AppColors.divider,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(hasDocument ? 'СТС загружено' : 'Добавить'),
      ),
    );
  }
}
