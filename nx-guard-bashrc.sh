# nx platform-guard — intercepts pnpm/npx so node_modules always matches
# the current OS before nx (or any pnpm-driven tool) runs against it.
#
# Source of truth: openclawDocker1/nx-guard-bashrc.sh
# Installed on Mac  : appended to ~/.zshrc by openclawDocker1/scripts/setup-mac-shell.sh
# Installed in Docker: appended to ~/.bashrc by openclawDocker1/Dockerfile

# Ensure ~/openclaw/bin is on PATH so the wrapper finds ensure-node-modules.sh
# by bare name (same path on Mac and inside the container via bind mount).
case ":$PATH:" in
    *":$HOME/openclaw/bin:"*) ;;
    *) export PATH="$HOME/openclaw/bin:$PATH" ;;
esac

_nx_find_git_root() {
    local d="$PWD"
    while [ "$d" != "/" ] && [ -n "$d" ]; do
        if [ -e "$d/.git" ]; then
            echo "$d"
            return 0
        fi
        d="$(dirname "$d")"
    done
    return 1
}

_nx_guard() {
    [ -n "${NX_GUARD_SKIP:-}" ] && return 0
    local root
    root="$(_nx_find_git_root)" || return 0
    command -v ensure-node-modules.sh >/dev/null 2>&1 || return 0
    ensure-node-modules.sh "$root" || return $?
}

pnpm() { _nx_guard || return $?; command pnpm "$@"; }
npx()  { _nx_guard || return $?; command npx  "$@"; }
