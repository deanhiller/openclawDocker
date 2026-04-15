# nx platform-guard — ensures pnpm/npx swap node_modules to match the current
# OS before running. The actual guard logic lives in real shim binaries at
# ~/openclaw/bin/{pnpm,npx} so subprocesses (IDE runners, nx workers, scripts
# invoked via sh -c) always see them, not just interactive shells.
#
# This rc-file block does ONE thing: put ~/openclaw/bin on PATH ahead of the
# real pnpm/npx so the shims win.
#
# Source of truth: openclawDocker1/nx-guard-bashrc.sh
# Installed on Mac  : appended to ~/.zshrc by openclawDocker1/scripts/setup-mac-shell.sh
# Installed in Docker: appended to ~/.bashrc by openclawDocker1/Dockerfile

case ":$PATH:" in
    *":$HOME/openclaw/bin:"*) ;;
    *) export PATH="$HOME/openclaw/bin:$PATH" ;;
esac
