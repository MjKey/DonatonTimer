# Timer for Donathon

**Donathon Timer** is a timer management application that integrates with DonationAlerts donations, allowing you to track and manage time based on received donations.
>> This is my first Flutter application, previously I only wrote in Python, I think it turned out pretty well, enjoy! 😺
>>
>> Useful for those who want a convenient and functional timer for donathon!

## 🎯 Key Features

- ### Windows Program Interface

  ![Interface](https://github.com/MjKey/DonatonTimer/blob/main/img/main.jpg?raw=true)

  - Dark theme available
  - Convenient controls
  - PIP mode

- **Web Interface for Timer Management:**
  - Start/Stop timer
  - Change timer time

- **Timer Management from Phone:**
  - Access to the web interface from mobile devices
  - Convenient timer management in the mobile version

- **Donation Integration:**
  - Display of recent donations
  - Display of top donors
  - Automatic time addition from donations
  - Setting - how many minutes to add for 100 rubles.

- **Mini Version for OBS Dock Panel:**
  - Simplified interface for use in OBS dock panel

## 🛠️ Installation and Launch

### Installing Releases

1. **Download the installer:**
   - Go to the [Releases](https://github.com/MjKey/DonatonTimer/releases) section and download the latest version of `DTimer-Setup.exe`.

2. **Run the installer:**
   - Double-click the downloaded `DTimer-Setup.exe` file and follow the on-screen instructions to install the application.
  
### Installing Artifacts

1. **Download the latest artifact:**
   - Go to the [Actions](https://github.com/MjKey/DonatonTimer/actions) section, choose the latest successful build (with a check mark)
   - At the bottom, there will be Artifacts -> Lastest - download, unzip to any folder.

2. **Run the timer:**
   - Double-click the `donat_timer.exe` file.
   - Profit!

## 🚀 Usage

- **Interface and more:**
  - `http://localhost:8080/timer` for insertion into the "Browser" source - the timer will be displayed in OBS.
  - Go to `http://localhost:8080/dashboard` for the web control panel in the browser.
  - `http://localhost:8080/mini` for embedding in the OBS dock panel*
 
  *For this, in OBS Studio -> Docks (D) -> Custom Browser Docks (C)
  ![Dock Panel Setup](https://github.com/MjKey/DonatonTimer/blob/main/img/dockpanel.jpg?raw=true)

## 💬 Questions and Support

If you have questions or encounter issues, feel free to open an issue on [GitHub](https://github.com/MjKey/DonatonTimer/issues).

## 📝 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

### Building from Source

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

   # Countdown for Donathon
