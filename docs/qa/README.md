# Журнал QA: frontend audit

06.09.2026. Flutter 3.47.2 / Dart 3.13.2, macOS arm64, изолированный Android AVD (`emulator-5556`). Снимки ниже относятся к исходному frontend-проходу с preview repositories. После него подключён PocketBase; серверные проверки приведены в таблице отдельно.

## Проверки

Полные рабочие логи находятся в `/tmp/vput-frontend-audit/`; воспроизводимый сценарий — `integration_test/frontend_audit_test.dart`, runner — `test_driver/frontend_audit_driver.dart`.

| Команда / проверка | Результат |
|---|---|
| Исходный `flutter analyze` | Без замечаний |
| Исходный `flutter test --reporter expanded` | 232 passed |
| Итоговый `flutter analyze` | Passed, no issues |
| Итоговый `flutter test --concurrency=2 --reporter expanded` | 249 passed |
| Native UI 375×812 dp | Passed; 44 контрольных снимка, один составной testWidgets и служебный teardown; заключительные правки текстов повторно проверены на 320 dp |
| Native UI 320×568 dp | Passed; 44 контрольных снимка после правок текстов и адаптивности |
| `flutter build apk --release` | Passed; `build/app/outputs/flutter-apk/app-release.apk`, 57.4 MB |
| `flutter build ios --release --no-codesign` | Passed; `build/ios/iphoneos/Runner.app`, 20.7 MB; без подписи, UI iOS не проверен |
| Backend smoke | Passed на чистой временной БД: migrations, auth, privacy, trips, booking, mock payment/refund, access rules, last-seat race |
| Production smoke | Passed через `https://pb.bookingtest26.ru`: HTTPS, OTP, runtime config, privacy-safe search |
| Чистая установка release APK, старт без сети | Passed; welcome отображается, `am start`: COLD / status ok |
| Force-stop и повторный старт release APK | Passed; welcome отображается, status ok; это не проверка сохранения сессии |

Неудачные промежуточные запуски выявили ошибки/регрессии, которые исправлялись до повторной проверки: переполнение рейтинга, запоздавший результат после logout, очередь snackbar, переполнение onboarding на 320 dp. В native-сценарии после ошибки отмены предусмотрено ожидание завершения snackbar, чтобы следующий тап не попадал в перекрывающий его текст уведомления.

## Снимки после исправлений

| Экран | PNG |
|---|---|
| Поездки, рейтинг без отзывов | [Список](12-trip-list.png) |
| Доступная поездка | [Детали](15-trip-available.png) |
| Отсутствующий backend бронирования | [Ошибка](17-booking-service-unavailable.png) |
| Отсутствующий backend отмены | [Ошибка отмены](20b-cancellation-service-unavailable.png) |
| Созданный пользователем профиль | [Профиль](21-profile.png) |
| Автомобиль | [Карточка](29-vehicle-details.png) |
| Результат публикации в preview | [Preview-публикация](40-published-preview.png) |

Эти PNG получены из Flutter surface; системные панели и performance по ним не оцениваются. Снимок публикации показывает локальный preview, не доказательство появления поездки на сервере. Полные серии — `/tmp/vput-frontend-audit/screenshots-375-final/` и `screenshots-320/`.

Отдельно сохранён [первый экран release APK без сети](release-offline.png), полученный через adb вместе с системными панелями.

Логи: [анализ](analyze-final.txt), [249 тестов](tests-final.txt), [форматирование](format-final.txt), [Android release](build-android-release.txt), [iOS unsigned](build-ios.txt), [холодный запуск без сети](release-offline-start.txt), [повторный запуск](release-relaunch.txt).

После native-прохода добавлена защита позднего результата выбора аватара при смене сессии/reset; она проверена тремя regression tests и полным набором 249 тестов. Итоговые сборки пересобраны с этой защитой; полный native-проход после неё повторно не запускался.

Android release сначала остановился на `packageRelease` с `No space left on device`. Освобождён воспроизводимый кэш сборок, Gradle перезапущен; повторная сборка успешна. Один прогон тестов, зависший после ошибки диска, остановлен и полностью повторён — приведён результат последнего успешного запуска. В логах сборок возможны предупреждения зависимостей о Java 8 / CocoaPods; ошибки Flutter analyze отсутствуют.

Временный QA-эмулятор завершён и его собственный AVD удалён после проверки. Пользовательский эмулятор не очищался. Скриншоты, журналы и готовые сборки сохранены.

## Как повторить

Использовать отдельный эмулятор без пользовательских данных. Заменить device id в командах на свой тестовый. Для плотности 320 dpi физические 750×1624 дают 375×812 dp, а 640×1136 — 320×568 dp.

```sh
flutter pub get
flutter analyze
flutter test --reporter expanded
adb -s emulator-5556 shell wm density 320
adb -s emulator-5556 shell wm size 750x1624
VPUT_QA_SCREENSHOTS=/tmp/vput-qa-375 flutter drive \
  --driver=test_driver/frontend_audit_driver.dart \
  --target=integration_test/frontend_audit_test.dart -d emulator-5556 \
  --dart-define=PREVIEW_MODE=true
adb -s emulator-5556 shell wm size 640x1136
VPUT_QA_SCREENSHOTS=/tmp/vput-qa-320 flutter drive \
  --driver=test_driver/frontend_audit_driver.dart \
  --target=integration_test/frontend_audit_test.dart -d emulator-5556 \
  --dart-define=PREVIEW_MODE=true
flutter build apk --release
flutter build ios --release --no-codesign
```

Frontend preview включается явно через `--dart-define=PREVIEW_MODE=true`. Для
серверного режима используется
`--dart-define=PB_BASE_URL=https://pb.bookingtest26.ru`. Текущая
Android release-конфигурация использует debug signing key: успешная
release-компиляция не означает готовность публикации в магазине.

Не проверены в текущем проходе: все Figma-frame pixel-for-pixel, iOS
UI/физические устройства, системная камера/файловый picker end-to-end, выдача
разрешения после постоянного отказа через настройки ОС, медленная реальная
сеть, realtime двух клиентов, performance в release, доступность с внешней
мобильной сети и восстановление БД из backup.
