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
