# CirnoDeck – webkit2gtk-4.1 Installer for Steam Deck

[![Download](https://img.shields.io/badge/Download-Latest%20Release-blue?style=for-the-badge&logo=github)](https://github.com/jdros15/Cirnodeck/releases/latest)

**CirnoDeck** is a lightweight, user-friendly graphical package manager designed specifically for the Steam Deck (SteamOS). It was created to simplify the installation of `webkit2gtk-4.1`, a critical dependency required to run the **Cirno Downloader** (from the **Anti Denuvo Sanctuary** Discord community) on the Steam Deck.

## ❓ Why This Exists

By default, SteamOS does not include `webkit2gtk-4.1`, which causes the Cirno Downloader and other similar third-party applications to fail on launch. This script automates the process of unlocking the filesystem, installing the package, and fixing common repository issues safely.

## 🌟 Features

- **Graphical User Interface:** No need to memorize complex terminal commands; uses a clean `zenity` interface.
- **SteamOS Optimized:** Automatically handles the Steam Deck's read-only filesystem by disabling it before installation and re-enabling it afterward.
- **Smart Keyring Management:** Automatically detects and fixes common Arch Linux keyring issues and initialization errors during installation.
- **Password Setup Guide:** Provides a helpful walkthrough to set a user password if one hasn't been configured yet (essential for `sudo` operations on SteamOS).

## 🚀 How to Use

### 1. Make the Script Executable
Before you can run the script, you must give it permission to execute:

- **Via File Manager (GUI):**
  1. Right-click on `cirnodeck.sh` -> **Properties**.
  2. Go to the **Permissions** tab.
  3. Check **Is executable** and click **OK**.
- **Via Terminal:**
  ```bash
  chmod +x cirnodeck.sh
  ```

### 2. Run the Script
- **Option A (Double-Click):** Double-click `cirnodeck.sh` in the file manager.
- **Option B (Terminal):** Right-click in the folder, select **Open Terminal Here**, type `./cirnodeck.sh`, and press **Enter**.

### 3. Follow the Prompts
The script will guide you through setting a password (if needed) and installing the `webkit2gtk-4.1` package. Once finished, you're ready to run **Cirno Downloader**!

## ⚙️ How it Works

The script automates several manual steps:
1. **Zenity Check:** Ensures the graphical dialog tool is available.
2. **Password Detection:** Verifies if the `deck` user has a password set.
3. **Filesystem Toggle:** Uses `steamos-readonly disable` and `enable` to safely modify the system.
4. **Pacman Integration:** Interacts directly with the Arch Linux package manager to handle dependencies and removals.
5. **Error Logging:** Captures and displays any terminal errors within the GUI for easier troubleshooting.

## ⚠️ Disclaimer

This script modifies the system partition of SteamOS. While it takes precautions by re-enabling the read-only mode, please be aware that system updates from Valve may occasionally revert these changes or uninstall packages added this way.

---

*Made for the Steam Deck community.*
