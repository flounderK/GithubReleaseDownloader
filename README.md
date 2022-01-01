# Github Release Downloader
Download and install the latest release packages from github repositories.

## Usage Example
The following commands will install the latest version of ghidra and make a local symlink accessible to the current user's path. `ghidra_10.1.1_PUBLIC_20211221.zip` is the current name of the release binary, and would be different for future releases:
```bash
./github_release_downloader.py -s 'NationalSecurityAgency/ghidra'
sudo -s ./github_release_installs.sh ./ghidra_10.1.1_PUBLIC_20211221.zip
sudo -s ./install_opt_symlinks.sh 'ghidra' 'ghidra'
mkdir -p ~/.local/bin
ln -f -s /opt/ghidra/ghidraRun "$HOME/.local/bin/ghidra"
export PATH="$HOME/.local/bin:$PATH"
```

