# Таймер для донатона | Donathon Countdown Timer
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/MjKey/DonatonTimer/total) ![GitHub Release](https://img.shields.io/github/v/release/MjKey/DonatonTimer)
 ![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/MjKey/DonatonTimer/Flutter.yml) [![Stars](https://img.shields.io/github/stars/MjKey/DonatonTimer?style=flat&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEiIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiI+PHBhdGggZD0iTTggLjI1YS43NS43NSAwIDAgMSAuNjczLjQxOGwxLjg4MiAzLjgxNSA0LjIxLjYxMmEuNzUuNzUgMCAwIDEgLjQxNiAxLjI3OWwtMy4wNDYgMi45Ny43MTkgNC4xOTJhLjc1MS43NTEgMCAwIDEtMS4wODguNzkxTDggMTIuMzQ3bC0zLjc2NiAxLjk4YS43NS43NSAwIDAgMS0xLjA4OC0uNzlsLjcyLTQuMTk0TC44MTggNi4zNzRhLjc1Ljc1IDAgMCAxIC40MTYtMS4yOGw0LjIxLS42MTFMNy4zMjcuNjY4QS43NS43NSAwIDAgMSA4IC4yNVoiIGZpbGw9IiNlYWM1NGYiLz48L3N2Zz4=&logoSize=auto&label=Stars&labelColor=666666&color=eac54f)](https://github.com/MjKey/DonatonTimer/)  
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81c%D0%BA%D0%B8%D0%B9-00677e?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiB2aWV3Qm94PSIwIDAgNjQgNjQiPgogIDxwYXRoIGZpbGw9IiMxYjc1YmIiIGQ9Ik0wIDI1aDY0djE0SDB6Ii8%2BCiAgPHBhdGggZmlsbD0iI2U2ZTdlOCIgZD0iTTU0IDEwSDEwQzMuMzczIDEwIDAgMTQuOTI1IDAgMjF2NGg2NHYtNGMwLTYuMDc1LTMuMzczLTExLTEwLTExIi8%2BCiAgPHBhdGggZmlsbD0iI2VjMWMyNCIgZD0iTTAgNDNjMCA2LjA3NSAzLjM3MyAxMSAxMCAxMWg0NGM2LjYyNyAwIDEwLTQuOTI1IDEwLTExdi00SDB2NCIvPgo8L3N2Zz4%3D)](https://github.com/MjKey/DonatonTimer/blob/main/README.md) [![English](https://img.shields.io/badge/English-00677e?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPCEtLSBpY29uNjY2LmNvbSAtIE1JTExJT05TIHZlY3RvciBJQ09OUyBGUkVFIC0tPjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgeD0iMHB4IiB5PSIwcHgiIHZpZXdCb3g9IjAgMCA1MTIgNTEyIiBzdHlsZT0iZW5hYmxlLWJhY2tncm91bmQ6bmV3IDAgMCA1MTIgNTEyOyIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSI%2BPHBhdGggc3R5bGU9ImZpbGw6IzQxNDc5QjsiIGQ9Ik00NzMuNjU1LDg4LjI3NkgzOC4zNDVDMTcuMTY3LDg4LjI3NiwwLDEwNS40NDMsMCwxMjYuNjIxVjM4NS4zOCBjMCwyMS4xNzcsMTcuMTY3LDM4LjM0NSwzOC4zNDUsMzguMzQ1aDQzNS4zMWMyMS4xNzcsMCwzOC4zNDUtMTcuMTY3LDM4LjM0NS0zOC4zNDVWMTI2LjYyMSBDNTEyLDEwNS40NDMsNDk0LjgzMyw4OC4yNzYsNDczLjY1NSw4OC4yNzZ6Ij48L3BhdGg%2BPHBhdGggc3R5bGU9ImZpbGw6I0Y1RjVGNTsiIGQ9Ik01MTEuNDY5LDEyMC4yODJjLTMuMDIyLTE4LjE1OS0xOC43OTctMzIuMDA3LTM3LjgxNC0zMi4wMDdoLTkuOTc3bC0xNjMuNTQsMTA3LjE0N1Y4OC4yNzZoLTg4LjI3NiB2MTA3LjE0N0w0OC4zMjIsODguMjc2aC05Ljk3N2MtMTkuMDE3LDAtMzQuNzkyLDEzLjg0Ny0zNy44MTQsMzIuMDA3bDEzOS43NzgsOTEuNThIMHY4OC4yNzZoMTQwLjMwOUwwLjUzMSwzOTEuNzE3IGMzLjAyMiwxOC4xNTksMTguNzk3LDMyLjAwNywzNy44MTQsMzIuMDA3aDkuOTc3bDE2My41NC0xMDcuMTQ3djEwNy4xNDdoODguMjc2VjMxNi41NzdsMTYzLjU0LDEwNy4xNDdoOS45NzcgYzE5LjAxNywwLDM0Ljc5Mi0xMy44NDcsMzcuODE0LTMyLjAwN2wtMTM5Ljc3OC05MS41OEg1MTJ2LTg4LjI3NkgzNzEuNjkxTDUxMS40NjksMTIwLjI4MnoiPjwvcGF0aD48Zz48cG9seWdvbiBzdHlsZT0iZmlsbDojRkY0QjU1OyIgcG9pbnRzPSIyODIuNDgzLDg4LjI3NiAyMjkuNTE3LDg4LjI3NiAyMjkuNTE3LDIyOS41MTcgMCwyMjkuNTE3IDAsMjgyLjQ4MyAyMjkuNTE3LDI4Mi40ODMgMjI5LjUxNyw0MjMuNzI0IDI4Mi40ODMsNDIzLjcyNCAyODIuNDgzLDI4Mi40ODMgNTEyLDI4Mi40ODMgNTEyLDIyOS41MTcgMjgyLjQ4MywyMjkuNTE3ICI%2BPC9wb2x5Z29uPjxwYXRoIHN0eWxlPSJmaWxsOiNGRjRCNTU7IiBkPSJNMjQuNzkzLDQyMS4yNTJsMTg2LjU4My0xMjEuMTE0aC0zMi40MjhMOS4yMjQsNDEwLjMxIEMxMy4zNzcsNDE1LjE1NywxOC43MTQsNDE4Ljk1NSwyNC43OTMsNDIxLjI1MnoiPjwvcGF0aD48cGF0aCBzdHlsZT0iZmlsbDojRkY0QjU1OyIgZD0iTTM0Ni4zODgsMzAwLjEzOEgzMTMuOTZsMTgwLjcxNiwxMTcuMzA1YzUuMDU3LTMuMzIxLDkuMjc3LTcuODA3LDEyLjI4Ny0xMy4wNzVMMzQ2LjM4OCwzMDAuMTM4eiI%2BPC9wYXRoPjxwYXRoIHN0eWxlPSJmaWxsOiNGRjRCNTU7IiBkPSJNNC4wNDksMTA5LjQ3NWwxNTcuNzMsMTAyLjM4N2gzMi40MjhMMTUuNDc1LDk1Ljg0MkMxMC42NzYsOTkuNDE0LDYuNzQ5LDEwNC4wODQsNC4wNDksMTA5LjQ3NXoiPjwvcGF0aD48cGF0aCBzdHlsZT0iZmlsbDojRkY0QjU1OyIgZD0iTTMzMi41NjYsMjExLjg2MmwxNzAuMDM1LTExMC4zNzVjLTQuMTk5LTQuODMxLTkuNTc4LTguNjA3LTE1LjY5OS0xMC44NkwzMDAuMTM4LDIxMS44NjJIMzMyLjU2NnoiPjwvcGF0aD48L2c%2BPC9zdmc%2B)](https://github.com/MjKey/DonatonTimer/blob/main/README-EN.md)  

[![Download Donation Countdown Timer](https://img.shields.io/badge/%D0%A1%D0%BA%D0%B0%D1%87%D0%B0%D1%82%D1%8C%20%7C%20Downloiad-8b00ff?logo=data%3Aimage%2Fsvg%2Bxml%3B%20charset%3Dutf-8%3Butf8%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0OCA0OCIgaWQ9IkRvd25sb2FkIj48cGF0aCBkPSJNMzggMThoLThWNkgxOHYxMmgtOGwxNCAxNCAxNC0xNHpNMTAgMzZ2NGgyOHYtNEgxMHoiIGZpbGw9IiNmZmZmZmYiIGNsYXNzPSJjb2xvcjAwMDAwMCBzdmdTaGFwZSI%2BPC9wYXRoPjxwYXRoIGZpbGw9Im5vbmUiIGQ9Ik0wIDBoNDh2NDhIMHoiPjwvcGF0aD48L3N2Zz4%3D)](https://github.com/MjKey/DonatonTimer/releases/download/2.0.3/DTimer-Setup.exe) [![Download Portable Version](https://img.shields.io/badge/Without_Installation-8b00ff?logo=data%3Aimage%2Fsvg%2Bxml%3B%20charset%3Dutf-8%3Butf8%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0OCA0OCIgaWQ9IkRvd25sb2FkIj48cGF0aCBkPSJNMzggMThoLThWNkgxOHYxMmgtOGwxNCAxNCAxNC0xNHpNMTAgMzZ2NGgyOHYtNEgxMHoiIGZpbGw9IiNmZmZmZmYiIGNsYXNzPSJjb2xvcjAwMDAwMCBzdmdTaGFwZSI%2BPC9wYXRoPjxwYXRoIGZpbGw9Im5vbmUiIGQ9Ik0wIDBoNDh2NDhIMHoiPjwvcGF0aD48L3N2Zz4%3D)](https://github.com/MjKey/DonatonTimer/releases/download/2.0.3/DonathonTimer.zip)

 
**Донатон Таймер** — это приложение для управления таймером, которое интегрируется с донатами DonationAlerts, позволяя отслеживать и управлять временем в зависимости от поступивших донатов.  
Также присутствует **оверлей таймера** для OBS, чтобы ваши зрители видели таймер!
>> Это моя первая разработка приложения на Flutter, до этого писал только на Python, думаю, получилось неплохо, пользуйтесь! 😺
>> 
>> Будет полезно тем, кто хочет себе удобный и функциональный таймер для донатона!

## 📋 Инструкция в Wiki ✬ [RU](https://github.com/MjKey/DonatonTimer/wiki/Настройка-и-использование-%5BRU%5D) | [EN](https://github.com/MjKey/DonatonTimer/wiki/Setting-and-using-%5BEN%5D) (⸝⸝ᵕᴗᵕ⸝⸝)

## 🍌 Поддержка сервисов:
|     Сервис     | Статус |  Комментарий |
|:--------------:|:------:|:------------:|
| DonationAlerts |    ✅   |   Работает   |
| Donate.Stream  |    ❌   |   В планах   |
| DonatePay      |    ❌   |   В планах   |
| Donatty        |    ❌   |   В планах   |
| StreamElements |    ❌   | Под вопросом |

## 🎯 Ключевые возможности

- ### Интерфейс программы под Windows

  ![Интерфейс](https://github.com/MjKey/DonatonTimer/blob/main/img/main.gif?raw=true)

  - Есть тёмная тема
  - Удобное управление
  - Пепежка

- **Веб-интерфейс для управления таймером:**
  - Старт/Стоп таймера
  - Изменение времени на таймере

- **Управление таймером с телефона:**
  - Доступ к веб-интерфейсу с мобильных устройств
  - Удобное управление таймером в мобильной версии

- **Интеграция с донатами:**
  - Отображение последних донатов
  - Отображение топ донатеров
  - Автоматичкое прибавление времени от доната
  - Настройка - сколько минут прибавить за 100 рублей.

- **Мини-версия для Док-Панели OBS:**
  - Упрощённый интерфейс для использования в док-панели OBS
 
## 🛠️ Установка и запуск

### Установка релизов

1. **Скачайте установочный файл:**
   - Перейдите в раздел [Releases](https://github.com/MjKey/DonatonTimer/releases) и скачайте последнюю версию `DTimer-Setup.exe`.

2. **Запустите установочный файл:**
   - Дважды щелкните по скачанному файлу `DTimer-Setup.exe` и следуйте инструкциям на экране для установки приложения.
  
### Установка артифактов

1. **Скачайте последний артифакт:**
   - Перейдите в раздел [Actions](https://github.com/MjKey/DonatonTimer/actions) выберите последний удавшийся билд (c галочкой)
   - Снизу будет Artifacts -> Lastest - скачиваем, разархивируем в любую папку.

2. **Запустите таймер**

## 🚀 Использование

- **Интерфейс и другое:**
  - `http://localhost:8080/timer` для вставки в источник "Бразуер" - таймер собствнно будет отображаться в OBS.
  - Перейдите на `http://localhost:8080/dashboard` для веб-панели управления в бразуере.
  - `http://localhost:8080/mini` для встравивание в док-панель* OBS.
 
  *Для этого в OBS Studio -> Док-панели (D) -> Пользовательские док-панели браузера (C)
  ![Настройка док-панели](https://github.com/MjKey/DonatonTimer/blob/main/img/dockpanel.jpg?raw=true)

## 💬 Вопросы и поддержка

Если у вас есть вопросы или вы столкнулись с проблемами, не стесняйтесь открыть issue на [GitHub](https://github.com/MjKey/DonatonTimer/issues).

## 📝 Лицензия

Этот проект лицензируется под лицензией MIT — см. [LICENSE](LICENSE) для подробностей.

---

### Сборка из исходного кода

1. **Клонируйте репозиторий:**

   ```bash
   git clone https://github.com/MjKey/DonatonTimer.git
   ```

2. **Перейдите в директорию проекта:**

   ```bash
   cd DonatonTimer
   ```

3. **Установите зависимости:**

   ```bash
   flutter pub get
   ```

4. **Соберите проект для Windows:**

   ```bash
   flutter build windows
   ```
   
   **Или запустите для Windows**

   ```bash
   flutter run -d windows
   ```

   # Обратный отчёт для донатона
