# Pop!_OS 22.04 to 24.04 Upgrade

Run these steps in order. Do not skip ahead.

## Pre-flight

- [ ] **Back up** `/home` (including hidden files), anything outside `/home`, and `/etc`. Use a snapshot or external drive, not the same disk.

## Upgrade

- [ ] **1. Fully update 22.04 first.** The upgrader requires this.
      ```bash
      sudo apt update
      sudo apt full-upgrade -y
      ```
      If a new kernel was installed, **reboot** before continuing.

- [ ] **2. Disable all third-party repos.** List them, then comment them out. Only Pop!_OS's own repos should remain enabled.
      ```bash
      ls /etc/apt/sources.list.d/
      sudo sed -i 's/^deb /#deb /' /etc/apt/sources.list.d/*.list
      ```

- [ ] **3. Install the official upgrader.**
      ```bash
      sudo apt install -y pop-upgrade
      ```

- [ ] **4. Start the upgrade.**
      ```bash
      sudo pop-upgrade release upgrade
      ```
      Read the release notes it shows, type `y` to confirm, then wait. Do not interrupt. ~30-60 min.

- [ ] **5. Reboot when prompted.**
      ```bash
      sudo reboot
      ```

- [ ] **6. Verify.**
      ```bash
      cat /etc/os-release
      ```
      Should show `VERSION_ID="24.04"`.

## Post-upgrade

- [ ] **7. Re-enable third-party repos** by finding their 24.04 / noble equivalents and uncommenting/updating sources. Skip any that don't have a noble version.

- [ ] **8. Update Meld installer.** Once on 24.04, run `./installers/meld.manual.bash --force` and revisit `installers/meld.manual.bash` for the new GTK 4 / libadwaita / GLib dep set.
