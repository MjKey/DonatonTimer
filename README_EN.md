# DonatonTimer | Countdown Timer

![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/MjKey/DonatonTimer/total) ![GitHub Release](https://img.shields.io/github/v/release/MjKey/DonatonTimer) [![Stars](https://img.shields.io/github/stars/MjKey/DonatonTimer?style=flat&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEiIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiI+PHBhdGggZD0iTTggLjI1YS43NS43NSAwIDAgMSAuNjczLjQxOGwxLjg4MiAzLjgxNSA0LjIxLjYxMmEuNzUuNzUgMCAwIDEgLjQxNiAxLjI3OWwtMy4wNDYgMi45Ny43MTkgNC4xOTJhLjc1MS43NTEgMCAwIDEtMS4wODguNzkxTDggMTIuMzQ3bC0zLjc2NiAxLjk4YS43NS43NSAwIDAgMS-1LjA4OC0uNzlsLjcyLTQuMTk0TC44MTggNi4zNzRhLjc1Ljc1IDAgMCAxIC40MTYtMS4yOGw0LjIxLS42MTFMNy4zMjcuNjY4QS43NS43NSAwIDAgMSA4IC4yNVoiIGZpbGw9IiNlYWM1NGYiLz48L3N2Zz4=&logoSize=auto&label=Stars&labelColor=666666&color=eac54f)](https://github.com/MjKey/DonatonTimer/)  

**DonatonTimer** is an application for managing donathon countdowns. It integrates with multiple donation platforms to track and add time dynamically based on incoming donations. It also features a fully customizable **timer overlay** for OBS with rich style generator!

> This is my first application developed on Flutter (previously I only coded in Python). I hope you find this tool helpful and convenient for your streams!

**Author:** [MjKey](https://mjkey.ru)  
**Support Project:** [CloudTips](https://pay.cloudtips.ru/p/cf634f74) • [Dalink](https://dalink.to/mjk3y)

---

## Wiki Documentation

✦ [RU Wiki](https://github.com/MjKey/DonatonTimer/wiki/Настройка-и-использование-%5BRU%5D)  
✦ [EN Wiki](https://github.com/MjKey/DonatonTimer/wiki/Setting-and-using-%5BEN%5D)

---

## Screenshots

<table align="center">
  <tr>
    <td align="center" valign="top">
      <b>Main Screen</b><br>
      <i>Timer control and stats</i><br><br>
      <img src=".github/ASSETS/donaton_timer_mainpage.png" width="260" alt="Main Screen">
    </td>
    <td align="center" valign="top">
      <b>Settings</b><br>
      <i>Donation services setup</i><br><br>
      <img src=".github/ASSETS/donaton_timer_settings.png" width="260" alt="Settings">
    </td>
    <td align="center" valign="top">
      <b>CSS Generator</b><br>
      <i>OBS Overlay Customization</i><br><br>
      <img src=".github/ASSETS/donaton_timer_csseditor.png" width="260" alt="CSS Generator">
    </td>
  </tr>
</table>

---

## Supported Services

| Service | Status | Comment |
| :---: | :---: | :--- |
| **DonationAlerts** | Yes | Working |
| **Donate.Stream** | Yes | Working |
| **DonatePay** | Yes | Working |
| **DonateX** | Yes | Working |
| **Donatty** | Yes | Working |
| **Streamer.bot** | Yes | BETA VER |
| **iHAQ Donate** | No | Planned |
| **StreamElements** | No | Planned |

---

## What's New in v3.0.X

- **Multi-service** — run DonationAlerts, DonatePay, Donate.Stream, DonateX, and Donatty simultaneously
- **CSS Generator** — customizable OBS overlay with Google Fonts integration
- **Separate Colors** customise different colors for hours, minutes, and seconds
- **Animations** — pulse, glow, bounce, and blink effects for text and separators
- **Mobile Control** — manage your timer from a phone using a simple QR code
- **Sound Alerts** — sound notifications for incoming donations
- **Auto-save** — timer state is automatically saved upon closing
- **Retro UI** — stylish 8-bit aesthetic (nes_ui)
- **Socket Selection** — manual socket configuration for DonationAlerts (socket/socket1-5)
- **URL Parsing** — extract widget tokens automatically by pasting widget URLs
- **Streamer.bot** — WebSocket integration with flexible mapping of events to donation equivalents
- **Currency Conversion** — automatic conversion of USD, EUR, KZT, etc. into RUB using current Central Bank exchange rates
- **Fixed Time** — option to add fixed time per donation event
- **Time Subtraction Mode** — configure the timer to subtract time instead of adding it

---

## Key Features

### Desktop App Interface (Windows)
- Retro 8-bit styled theme
- Real-time switching between Light and Dark themes
- Intuitive control dashboard and connection status indicators
- Helpful tooltips on hover for all buttons

### Web Panel Administrator Interface
- Remote Start/Stop and time adjustments
- Interactive feed with recent donations and top-donators
- Responsive mobile layout with fast QR-code connection

### Donation Integrations
- Automatic time calculations based on customizable rate formulas
- Support for multiple donation platforms running at the same time
- Flexible mapper to translate Streamer.bot events into virtual currencies
- Built-in multi-source converter so you never lose international donations

### OBS Style Generator
- 14 pre-designed layout presets (Cyberpunk, Matrix, Neon, Kawaii, etc.)
- Direct Google Fonts library integration
- Fine-grained controls for individual HH:MM:SS styling

---

## Installation & Setup

### Installing Official Releases

1. **Download the installer:**
   - Go to [Releases](https://github.com/MjKey/DonatonTimer/releases) and download the latest setup file: `DonatonTimer_vX.X.X_Setup.exe`

2. **Run the setup:**
   - Run the downloaded installer and follow the on-screen instructions.

### Installing Artifacts (Bleeding-edge Alpha builds)

1. **Download the latest artifact:**
   - Go to [Actions](https://github.com/MjKey/DonatonTimer/actions), select the latest successful workflow run (indicated by green checkmark).
   - Scroll down to *Artifacts* -> download *Latest*. Extract the ZIP archive to any directory.
   - **ONLY FOR TESTING PURPOSES! THESE ARE NOT STABLE RELEASES!**

2. **Run the Timer**

---

## Usage

### Local Server URLs (Default)

| URL | Description |
| :--- | :--- |
| `http://localhost:7575/timer` | Timer overlay for OBS Browser Source |
| `http://localhost:7575/dashboard` | Web Administrator Panel |
| `http://localhost:7575/mini` | Compact mini-version optimized for OBS Dok Panels |

> **Port Migration Notice:** Since version v3.0.6, the app uses port `7575` (HTTP) and `3434` (WS) by default to prevent port conflicts with Streamer.bot (which defaults to 8080). Upon launching, the app will automatically suggest migrating your old config to these ports.

### OBS Studio Dock Panel Setup
In OBS Studio -> Docks -> Custom Browser Docks... -> Add name and paste `http://localhost:7575/mini`.

### Streamer.bot Integration Guide
Detailed instructions are available in the [Wiki](https://github.com/MjKey/DonatonTimer/wiki).

In short:
1. In Streamer.bot, enable the WebSocket server: `Servers/Clients` -> `WebSocket Server` -> Enable *Auto Start* and click *Start*.
2. In DonatonTimer -> Settings -> *Streamer.bot*, enable the integration and specify the WebSocket address (default is `ws://127.0.0.1:8080/`).
3. Add event mappings: specify the Event Source (e.g., `Twitch`), Event Type (e.g., `Sub`), and the virtual donation amount.

---

## Data Storage

Application configuration and local database are stored at:
```
%APPDATA%\MerryJoyKeyStudio\DonatonTimer\data.json
```

---

## Default Network Ports

| Port | Description |
|------|------------|
| 7575 | HTTP Server (OBS overlay and dashboard) |
| 3434 | WebSocket Server (for synchronisation and phone connection) |

> Legacy ports 8080/4040 were migrated to avoid socket conflicts with Streamer.bot.

---

## Feedback & Support

If you have any questions or encounter bugs, please feel free to open an Issue on [GitHub](https://github.com/MjKey/DonatonTimer/issues).

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Compiling from Source

To compile this project locally, you must have Flutter SDK installed.

```bash
# 1. Clone the repository
git clone https://github.com/MjKey/DonatonTimer.git
cd DonatonTimer

# 2. Get dependencies
flutter pub get

# 3. Run under Windows in debug mode
flutter run -d windows

# 4. Build release bundle
flutter build windows
```

### Building Installer (Inno Setup)
```bash
# Compile project
flutter build windows

# Compile installer (requires ISCC and Inno Setup 6)
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup.iss
```

---

**Countdown Timer for Streams**

---

Made by [MjKey](https://mjkey.ru) with ❤️  
I will be highly grateful for any financial and informational support!
