# 🎮 Таймер для донатона | Donathon Countdown Timer

![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/MjKey/DonatonTimer/total) ![GitHub Release](https://img.shields.io/github/v/release/MjKey/DonatonTimer) [![Stars](https://img.shields.io/github/stars/MjKey/DonatonTimer?style=flat&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEiIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiI+PHBhdGggZD0iTTggLjI1YS43NS43NSAwIDAgMSAuNjczLjQxOGwxLjg4MiAzLjgxNSA0LjIxLjYxMmEuNzUuNzUgMCAwIDEgLjQxNiAxLjI3OWwtMy4wNDYgMi45Ny43MTkgNC4xOTJhLjc1MS43NTEgMCAwIDEtMS4wODguNzkxTDggMTIuMzQ3bC0zLjc2NiAxLjk4YS43NS43NSAwIDAgMS0xLjA4OC0uNzlsLjcyLTQuMTk0TC44MTggNi4zNzRhLjc1Ljc1IDAgMCAxIC40MTYtMS4yOGw0LjIxLS42MTFMNy4zMjcuNjY4QS43NS43NSAwIDAgMSA4IC4yNVoiIGZpbGw9IiNlYWM1NGYiLz48L3N2Zz4=&logoSize=auto&label=Stars&labelColor=666666&color=eac54f)](https://github.com/MjKey/DonatonTimer/)  

**DonatonTimer** — приложение для управления таймером донатона, которое интегрируется с несколькими донат-сервисами, позволяя отслеживать и управлять временем в зависимости от поступивших донатов. Также присутствует **оверлей таймера** для OBS с кастомизируемыми стилями!

> Это моя первая разработка приложения на Flutter, до этого писал только на Python, думаю, получилось неплохо, пользуйтесь! 😺
>
> Будет полезно тем, кто хочет себе удобный и функциональный таймер для донатона!

**Автор:** [MjKey](https://mjkey.ru)

## 📋 Инструкция в Wiki

✬ [RU](https://github.com/MjKey/DonatonTimer/wiki/Настройка-и-использование-%5BRU%5D) | [EN](https://github.com/MjKey/DonatonTimer/wiki/Setting-and-using-%5BEN%5D) (⸝⸝ᵕᴗᵕ⸝⸝)

## 🍌 Поддержка сервисов

|     Сервис     | Статус |  Комментарий  |
|:--------------:|:------:|:-------------:|
| DonationAlerts |   ✅   |   Работает    |
| Donate.Stream  |   ✅   |   Работает    |
| DonatePay      |   ✅   |   Работает    |
| DonateX        |   ✅   |   Работает    |
| Donatty        |   ✅   |   Работает (SSE) |
| Streamer.bot   |   ✅   |   Работает (WebSocket) |
| iHAQ Donate    |   ❌   |   В планах    |
| StreamElements |   ❌   |   В планах    |

## ✨ Что нового в v3.0.5

- 🤖 **Streamer.bot** — интеграция через WebSocket с гибкой привязкой событий к суммам донатов
- 🎁 **Donatty** — поддержка нового сервиса через SSE (Server-Sent Events)
- 🔗 **DonateX** — поддержка нового сервиса донатов
- 🔌 **Новые порты** — 7575 (HTTP) и 3434 (WS) по умолчанию, чтобы избежать конфликтов со Streamer.bot
- ⚠️ **Предупреждение о старых портах** — автоматическая миграция с 8080/4040
- ⏱️ **Фиксированное время** — режим фиксированного времени за каждый донат
- ➖ **Режим убавления** — таймер можно настроить на убавление времени от донатов

## ✨ Что было в v3.0.0

- 🔗 **Мульти-сервис** — DonationAlerts, DonatePay, Donate.Stream одновременно
- 🎨 **CSS генератор** — кастомизируемый оверлей для OBS с Google Fonts
- 🎭 **Раздельные цвета** — часы, минуты, секунды могут быть разных цветов
- ✨ **Анимации** — pulse, glow, bounce, blink для текста и разделителей
- 📱 **Мобильное управление** — контроль таймера через QR код
- 🔊 **Звуковые уведомления** — оповещения о донатах
- 💾 **Автосохранение** — таймер сохраняется при закрытии
- 🎮 **Ретро UI** — стильный 8-bit интерфейс (nes_ui)
- 🔌 **Выбор сокета** — для DonationAlerts можно выбрать socket/socket1-5
- 🔗 **Парсинг URL** — можно вставить ссылку виджета вместо токена

## 🎯 Ключевые возможности

### Интерфейс программы под Windows
- Ретро 8-bit стиль
- Тёмная и светлая тема
- Удобное управление
- Индикаторы статуса подключения
- Тултипы с подсказками при наведении на кнопки

### Веб-интерфейс для управления таймером
- Старт/Стоп таймера
- Изменение времени на таймере
- Отображение последних донатов
- Отображение топ донатеров

### Управление таймером с телефона
- Доступ к веб-интерфейсу с мобильных устройств
- QR код для быстрого подключения
- Удобное управление в мобильной версии

### Интеграция с донатами
- Автоматическое прибавление времени от доната
- Настройка — сколько рублей = 1 час
- Поддержка нескольких сервисов одновременно
- Интеграция со Streamer.bot (события → суммы донатов)

### CSS генератор стилей
- 14 готовых пресетов (Cyberpunk, Matrix, Kawaii и др.)
- Google Fonts
- Анимации текста и разделителей
- Раздельные цвета для HH:MM:SS

### Мини-версия для Dok-Панели OBS
- Упрощённый интерфейс для использования в dok-панели OBS

## 🛠️ Установка и запуск

### Установка релизов

1. **Скачайте установочный файл:**
   - Перейдите в раздел [Releases](https://github.com/MjKey/DonatonTimer/releases) и скачайте последнюю версию `DonatonTimer_vX.X.X_Setup.exe`

2. **Запустите установочный файл:**
   - Дважды щелкните по скачанному файлу и следуйте инструкциям на экране

### Установка артифактов

1. **Скачайте последний артифакт:**
   - Перейдите в раздел [Actions](https://github.com/MjKey/DonatonTimer/actions), выберите последний удавшийся билд (с галочкой)
   - Снизу будет Artifacts → Latest — скачиваем, разархивируем в любую папку

2. **Запустите таймер**

## 🚀 Использование

### URL адреса (по умолчанию)

| URL | Назначение |
|-----|------------|
| `http://localhost:7575/timer` | Оверлей таймера для OBS Browser Source |
| `http://localhost:7575/dashboard` | Веб-панель управления |
| `http://localhost:7575/mini` | Мини-версия для dok-панели OBS |

> ⚠️ **Старые порты:** В версиях до v3.0.5 использовались порты 8080 (HTTP) и 4040 (WS). При первом запуске приложение предложит автоматически переключиться на новые порты 7575/3434.

### Настройка dok-панели OBS

В OBS Studio → Dok-панели (D) → Пользовательские dok-панели браузера (C)

### Настройка Streamer.bot

Подробная инструкция в [Wiki](https://github.com/MjKey/DonatonTimer/wiki).

Кратко:
1. В Streamer.bot включите **WebSocket Server** (Servers/Clients → WebSocket Server → Auto Start)
2. В DonatonTimer → Настройки → Streamer.bot укажите адрес WebSocket (по умолчанию `ws://127.0.0.1:8080/`)
3. Включите сервис и нажмите **Сохранить**
4. Добавьте привязки событий: укажите Source (например, `Twitch`), Type (например, `Sub`) и эквивалентную сумму доната

## 📁 Хранение данных

Настройки хранятся в:
```
%APPDATA%\MerryJoyKeyStudio\DonatonTimer\data.json
```

## 🔧 Порты по умолчанию

| Порт | Назначение |
|------|------------|
| 7575 | HTTP сервер (OBS оверлей) |
| 3434 | WebSocket (мобильное управление) |

> Старые порты 8080/4040 были изменены для предотвращения конфликтов со Streamer.bot.

## 💬 Вопросы и поддержка

Если у вас есть вопросы или вы столкнулись с проблемами, не стесняйтесь открыть issue на [GitHub](https://github.com/MjKey/DonatonTimer/issues).

## 📝 Лицензия

Этот проект лицензируется под лицензией MIT — см. [LICENSE](LICENSE) для подробностей.

---

## 🔨 Сборка из исходного кода

```bash
# Клонировать репозиторий
git clone https://github.com/MjKey/DonatonTimer.git
cd DonatonTimer

# Установить зависимости
flutter pub get

# Запустить
flutter run -d windows

# Собрать релиз
flutter build windows
```

### Сборка установщика

```bash
# Собрать приложение
flutter build windows

# Собрать установщик (требуется Inno Setup 6)
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup.iss
```

---

**Обратный отсчёт для донатона** 🎮

---

Made with ❤️ by [MjKey](https://mjkey.ru)
Буду рад любой финансовой поддержки!
