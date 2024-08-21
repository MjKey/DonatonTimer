# Donathon Countdown Timer | Таймер для донатона 
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/MjKey/DonatonTimer/total) ![GitHub Release](https://img.shields.io/github/v/release/MjKey/DonatonTimer)
 ![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/MjKey/DonatonTimer/Flutter.yml) [![Stars](https://img.shields.io/github/stars/MjKey/DonatonTimer?style=flat&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEiIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiI+PHBhdGggZD0iTTggLjI1YS43NS43NSAwIDAgMSAuNjczLjQxOGwxLjg4MiAzLjgxNSA0LjIxLjYxMmEuNzUuNzUgMCAwIDEgLjQxNiAxLjI3OWwtMy4wNDYgMi45Ny43MTkgNC4xOTJhLjc1MS43NTEgMCAwIDEtMS4wODguNzkxTDggMTIuMzQ3bC0zLjc2NiAxLjk4YS43NS43NSAwIDAgMS0xLjA4OC0uNzlsLjcyLTQuMTk0TC44MTggNi4zNzRhLjc1Ljc1IDAgMCAxIC40MTYtMS4yOGw0LjIxLS42MTFMNy4zMjcuNjY4QS43NS43NSAwIDAgMSA4IC4yNVoiIGZpbGw9IiNlYWM1NGYiLz48L3N2Zz4=&logoSize=auto&label=Stars&labelColor=666666&color=eac54f)](https://github.com/MjKey/DonatonTimer/)  
[![Русский](https://img.shields.io/badge/%D0%A0%D1%83%D1%81c%D0%BA%D0%B8%D0%B9-00677e?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiB2aWV3Qm94PSIwIDAgNjQgNjQiPgogIDxwYXRoIGZpbGw9IiMxYjc1YmIiIGQ9Ik0wIDI1aDY0djE0SDB6Ii8%2BCiAgPHBhdGggZmlsbD0iI2U2ZTdlOCIgZD0iTTU0IDEwSDEwQzMuMzczIDEwIDAgMTQuOTI1IDAgMjF2NGg2NHYtNGMwLTYuMDc1LTMuMzczLTExLTEwLTExIi8%2BCiAgPHBhdGggZmlsbD0iI2VjMWMyNCIgZD0iTTAgNDNjMCA2LjA3NSAzLjM3MyAxMSAxMCAxMWg0NGM2LjYyNyAwIDEwLTQuOTI1IDEwLTExdi00SDB2NCIvPgo8L3N2Zz4%3D)](https://github.com/MjKey/DonatonTimer/blob/main/README.md) [![English](https://img.shields.io/badge/English-00677e?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPCEtLSBpY29uNjY2LmNvbSAtIE1JTExJT05TIHZlY3RvciBJQ09OUyBGUkVFIC0tPjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgeD0iMHB4IiB5PSIwcHgiIHZpZXdCb3g9IjAgMCA1MTIgNTEyIiBzdHlsZT0iZW5hYmxlLWJhY2tncm91bmQ6bmV3IDAgMCA1MTIgNTEyOyIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSI%2BPHBhdGggc3R5bGU9ImZpbGw6IzQxNDc5QjsiIGQ9Ik00NzMuNjU1LDg4LjI3NkgzOC4zNDVDMTcuMTY3LDg4LjI3NiwwLDEwNS40NDMsMCwxMjYuNjIxVjM4NS4zOCBjMCwyMS4xNzcsMTcuMTY3LDM4LjM0NSwzOC4zNDUsMzguMzQ1aDQzNS4zMWMyMS4xNzcsMCwzOC4zNDUtMTcuMTY3LDM4LjM0NS0zOC4zNDVWMTI2LjYyMSBDNTEyLDEwNS40NDMsNDk0LjgzMyw4OC4yNzYsNDczLjY1NSw4OC4yNzZ6Ij48L3BhdGg%2BPHBhdGggc3R5bGU9ImZpbGw6I0Y1RjVGNTsiIGQ9Ik01MTEuNDY5LDEyMC4yODJjLTMuMDIyLTE4LjE1OS0xOC43OTctMzIuMDA3LTM3LjgxNC0zMi4wMDdoLTkuOTc3bC0xNjMuNTQsMTA3LjE0N1Y4OC4yNzZoLTg4LjI3NiB2MTA3LjE0N0w0OC4zMjIsODguMjc2aC05Ljk3N2MtMTkuMDE3LDAtMzQuNzkyLDEzLjg0Ny0zNy44MTQsMzIuMDA3bDEzOS43NzgsOTEuNThIMHY4OC4yNzZoMTQwLjMwOUwwLjUzMSwzOTEuNzE3IGMzLjAyMiwxOC4xNTksMTguNzk3LDMyLjAwNywzNy44MTQsMzIuMDA3aDkuOTc3bDE2My41NC0xMDcuMTQ3djEwNy4xNDdoODguMjc2VjMxNi41NzdsMTYzLjU0LDEwNy4xNDdoOS45NzcgYzE5LjAxNywwLDM0Ljc5Mi0xMy44NDcsMzcuODE0LTMyLjAwN2wtMTM5Ljc3OC05MS41OEg1MTJ2LTg4LjI3NkgzNzEuNjkxTDUxMS40NjksMTIwLjI4MnoiPjwvcGF0aD48Zz48cG9seWdvbiBzdHlsZT0iZmlsbDojRkY0QjU1OyIgcG9pbnRzPSIyODIuNDgzLDg4LjI3NiAyMjkuNTE3LDg4LjI3NiAyMjkuNTE3LDIyOS41MTcgMCwyMjkuNTE3IDAsMjgyLjQ4MyAyMjkuNTE3LDI4Mi40ODMgMjI5LjUxNyw0MjMuNzI0IDI4Mi40ODMsNDIzLjcyNCAyODIuNDgzLDI4Mi40ODMgNTEyLDI4Mi40ODMgNTEyLDIyOS41MTcgMjgyLjQ4MywyMjkuNTE3ICI%2BPC9wb2x5Z29uPjxwYXRoIHN0eWxlPSJmaWxsOiNGRjRCNTU7IiBkPSJNMjQuNzkzLDQyMS4yNTJsMTg2LjU4My0xMjEuMTE0aC0zMi40MjhMOS4yMjQsNDEwLjMxIEMxMy4zNzcsNDE1LjE1NywxOC43MTQsNDE4Ljk1NSwyNC43OTMsNDIxLjI1MnoiPjwvcGF0aD48cGF0aCBzdHlsZT0iZmlsbDojRkY0QjU1OyIgZD0iTTM0Ni4zODgsMzAwLjEzOEgzMTMuOTZsMTgwLjcxNiwxMTcuMzA1YzUuMDU3LTMuMzIxLDkuMjc3LTcuODA3LDEyLjI4Ny0xMy4wNzVMMzQ2LjM4OCwzMDAuMTM4eiI%2BPC9wYXRoPjxwYXRoIHN0eWxlPSJmaWxsOiNGRjRCNTU7IiBkPSJNNC4wNDksMTA5LjQ3NWwxNTcuNzMsMTAyLjM4N2gzMi40MjhMMTUuNDc1LDk1Ljg0MkMxMC42NzYsOTkuNDE0LDYuNzQ5LDEwNC4wODQsNC4wNDksMTA5LjQ3NXoiPjwvcGF0aD48cGF0aCBzdHlsZT0iZmlsbDojRkY0QjU1OyIgZD0iTTMzMi41NjYsMjExLjg2MmwxNzAuMDM1LTExMC4zNzVjLTQuMTk5LTQuODMxLTkuNTc4LTguNjA3LTE1LjY5OS0xMC44NkwzMDAuMTM4LDIxMS44NjJIMzMyLjU2NnoiPjwvcGF0aD48L2c%2BPC9zdmc%2B)](https://github.com/MjKey/DonatonTimer/blob/main/README-EN.md)  

[![Download Donation Countdown Timer](https://img.shields.io/badge/%D0%A1%D0%BA%D0%B0%D1%87%D0%B0%D1%82%D1%8C%20%7C%20Downloiad-8b00ff?logo=data%3Aimage%2Fsvg%2Bxml%3B%20charset%3Dutf-8%3Butf8%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0OCA0OCIgaWQ9IkRvd25sb2FkIj48cGF0aCBkPSJNMzggMThoLThWNkgxOHYxMmgtOGwxNCAxNCAxNC0xNHpNMTAgMzZ2NGgyOHYtNEgxMHoiIGZpbGw9IiNmZmZmZmYiIGNsYXNzPSJjb2xvcjAwMDAwMCBzdmdTaGFwZSI%2BPC9wYXRoPjxwYXRoIGZpbGw9Im5vbmUiIGQ9Ik0wIDBoNDh2NDhIMHoiPjwvcGF0aD48L3N2Zz4%3D)](https://github.com/MjKey/DonatonTimer/releases/download/2.0.3/DTimer-Setup.exe) [![Download Portable Version](https://img.shields.io/badge/Without_Installation-8b00ff?logo=data%3Aimage%2Fsvg%2Bxml%3B%20charset%3Dutf-8%3Butf8%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0OCA0OCIgaWQ9IkRvd25sb2FkIj48cGF0aCBkPSJNMzggMThoLThWNkgxOHYxMmgtOGwxNCAxNCAxNC0xNHpNMTAgMzZ2NGgyOHYtNEgxMHoiIGZpbGw9IiNmZmZmZmYiIGNsYXNzPSJjb2xvcjAwMDAwMCBzdmdTaGFwZSI%2BPC9wYXRoPjxwYXRoIGZpbGw9Im5vbmUiIGQ9Ik0wIDBoNDh2NDhIMHoiPjwvcGF0aD48L3N2Zz4%3D)](https://github.com/MjKey/DonatonTimer/releases/download/2.0.3/DonathonTimer.zip)  

**Donaton Timer** is an app for managing a timer that integrates with DonationAlerts donations, letting you track and manage time based on incoming donations.  
There's also a **timer overlay** for OBS, so your viewers can see the timer!
>> This is my first Flutter app; before this, I only worked with Python. I think it turned out pretty well, so feel free to use it! 😺
>> 
>> It's perfect for anyone looking for a handy and functional timer for donation streams!

## 📋 Wiki Instructions ✬ [RU](https://github.com/MjKey/DonatonTimer/wiki/Настройка-и-использование-%5BRU%5D) | [EN](https://github.com/MjKey/DonatonTimer/wiki/Setting-and-using-%5BEN%5D) (⸝⸝ᵕᴗᵕ⸝⸝)

## 🍌 Supported Services:
|     Service     | Status |  Comment     |
|:---------------:|:------:|:------------:|
| DonationAlerts  |    ✅   |   Works      |
| Donate.Stream   |    ❌   |   Coming Soon|
| DonatePay       |    ❌   |   Coming Soon|
| Donatty         |    ❌   |   Coming Soon|
| StreamElements  |    ❌   |   Coming Soon|

## 🎯 Key Features

- ### Windows App Interface

  ![Interface](https://github.com/MjKey/DonatonTimer/blob/main/img/main.gif?raw=true)

  - Dark theme
  - Easy to use
  - Peppy design

- **Web Interface for Timer Management:**
  - Start/Stop the timer
  - Change the timer duration

- **Control the Timer from Your Phone:**
  - Access the web interface from mobile devices
  - Manage the timer easily on mobile

- **Donation Integration:**
  - Display recent donations
  - Show top donors
  - Auto-add time based on donations
  - Configure how many minutes to add per 100 rubles

- **Mini Version for OBS Dock Panel:**
  - Simplified interface for OBS dock panel use

## 🛠️ Installation and Setup

### Release Installation

1. **Download the installer:**
   - Go to the [Releases](https://github.com/MjKey/DonatonTimer/releases) section and download the latest `DTimer-Setup.exe`.

2. **Run the installer:**
   - Double-click the downloaded `DTimer-Setup.exe` file and follow the on-screen instructions to install the app.
  
### Artifact Installation

1. **Download the latest artifact:**
   - Go to the [Actions](https://github.com/MjKey/DonatonTimer/actions) section, select the latest successful build (with a checkmark)
   - Download the Artifacts -> Latest, extract it to any folder.

2. **Run the timer**

## 🚀 Usage

- **Interface and More:**
  - `http://localhost:8080/timer` for embedding in a "Browser" source — the timer will appear in OBS.
  - Go to `http://localhost:8080/dashboard` for the web management panel in your browser.
  - `http://localhost:8080/mini` for embedding in OBS dock panel*

  *For this, in OBS Studio -> Dock Panels (D) -> Custom Browser Dock Panels (C)
  ![Dock Panel Setup](https://github.com/MjKey/DonatonTimer/blob/main/img/dockpanel.jpg?raw=true)

## 💬 Questions and Support

If you have any questions or run into issues, don’t hesitate to open an issue on [GitHub](https://github.com/MjKey/DonatonTimer/issues).

## 📝 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

### Building from Source Code

1. **Clone the repository:**

   ```bash
   git clone https://github.com/MjKey/DonatonTimer.git
   ```

2. **Navigate to the project directory:**

   ```bash
   cd DonatonTimer
   ```

3. **Install dependencies:**

   ```bash
   flutter pub get
   ```

4. **Build the project for Windows:**

   ```bash
   flutter build windows
   ```

   **Or run for Windows**

   ```bash
   flutter run -d windows
   ```

   # Countdown for the donation stream
