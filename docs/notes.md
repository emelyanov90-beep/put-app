Если активен flutter run:
- r — hot reload.
- R — полный hot restart приложения.
- q — остановить приложение.

Перезапустить сам Android-эмулятор:
adb -s emulator-5554 reboot
Запустить Vput_API36 заново:
flutter emulators --launch Vput_API36

Запуск приложения с backend (бронирование, оплата, отмена работают только так):
flutter run -d emulator-5554 --dart-define-from-file=config/dev.json

Без --dart-define-from-file обычное приложение показывает ошибку конфигурации и
не подмешивает демо-данные. Preview запускается только явно:
flutter run -d emulator-5554 --dart-define=PREVIEW_MODE=true
