## 📖 How to Use CirnoDeck on Steam Deck

This tutorial will show you how to set up and run the `cirnodeck.sh` script to install the dependencies for **Cirno Downloader**.

---

### Step 1: Make it Executable

Before you can run the script, you must give it permission to execute:

1. Right-click on `cirnodeck.sh`.
2. Select **Properties**.
3. Go to the **Permissions** tab.
4. Check the box for **Is executable**.
5. Click **OK**.

*Alternatively, via terminal:*
Open a terminal in the folder and run: `chmod +x cirnodeck.sh`

---

### Step 2: Run the Script

You can run the script in two ways:

#### Option A: Double-Click (GUI)
1. Double-click `cirnodeck.sh` in the file manager.
2. If prompted, select **Execute** or **Run in Terminal**.

#### Option B: Terminal Command
1. Right-click in the folder and select **Open Terminal Here** (Konsole).
2. Type `./cirnodeck.sh` and press **Enter**.

---

### Step 3: Follow the Prompts

- **Password Setup:** If you haven't set a password for your `deck` user, the script will guide you through setting one (required for `sudo`).
- **Installation:** Select **Install webkit2gtk-4.1** from the menu.
- **Completion:** Wait for the "Success" message, then you're ready to run **Cirno Downloader**!
