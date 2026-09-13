#!/bin/bash

function check_container() {
    echo "-> Checking for Existing '$1' Container"
    if [[ -z $(podman ps -a --format "{{.Names}}" | grep "$1") ]]; then
        echo "-> Container '$1' Does not Exist"
        export status=1
    else
        echo "-> Container '$1' Already Exists"
        export status=0
    fi
}

function start_container() {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Starting Container '$1'"
        podman start "$1"
    fi
}

function start_container_and_exit() {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Starting Container '$1'"
        podman start "$1"
    fi
    exit ${status}
}

function stop_container() {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Stopping Container '$1'"
        podman stop "$1"
    fi
}

function stop_container_and_exit() {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Stopping Container '$1'"
        podman stop "$1"
    fi
    exit ${status}
}

function remove_container () {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Removing Container '$1'"
        podman rm -f "$1"
    fi
}

function generate_container_quadlet() {
    echo "-> Making '$1' Container's Quadlet File"
    ${SELFHOST_ROOT_DIR:-$HOME/selfhost}/bin/podlet --file . --install --overwrite --description "$1" generate container "$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|$HOME|%h|g" "$1.container"
    else
        sed -i "s|$HOME|%h|g" "$1.container"
    fi
    echo "-> Generated quadlet file: $1.container"
    echo "-> Note: Consider committing this file directly for better version control"
}

# inject_env_into_quadlet <app_name> <env_line>
#
# Inserts a systemd Environment= directive under the [Service] section of
# a generated quadlet (<app>.container). Idempotent: skips if the line
# already exists. If [Service] section is missing, appends one.
#
# This is the mechanism for the Podman 5.x --dns append-not-override quirk
# (see .cursor/rules/podman-dns-bypass.mdc and docs/DNS_ARCHITECTURE.md).
# By injecting `Environment=CONTAINERS_CONF=/dev/null` we make systemd invoke
# podman WITHOUT loading containers.conf, so --dns flags in the [Container]
# section are the sole source of /etc/resolv.conf.
function inject_env_into_quadlet() {
    local appName="$1"
    local envLine="$2"   # e.g. "Environment=CONTAINERS_CONF=/dev/null"
    local quadletFile="$appName.container"

    if [[ ! -f "$quadletFile" ]]; then
        echo "-> ERROR: $quadletFile not found; call 'generate-con-quadlet' first"
        return 1
    fi

    if grep -qF "$envLine" "$quadletFile"; then
        echo "-> '$envLine' already present in $quadletFile (skipping)"
        return 0
    fi

    echo "-> Injecting '$envLine' under [Service] in $quadletFile"
    if grep -q "^\[Service\]" "$quadletFile"; then
        awk -v line="$envLine" '
            { print }
            /^\[Service\]/ && !done { print line; done=1 }
        ' "$quadletFile" > "$quadletFile.tmp" && mv "$quadletFile.tmp" "$quadletFile"
    else
        printf '\n[Service]\n%s\n' "$envLine" >> "$quadletFile"
    fi
}

function install_container_quadlet() {
    folder=$2
    if [[ ! -f "$HOME/selfhost/apps/$folder/$1.container" ]]; then
        echo "-> '$1' Container's Quadlet File Does Not Exists"
        exit 1
    fi

    mkdir -p ~/.config/containers/systemd
    cd ~/.config/containers/systemd
    echo "-> Installing '$1' Container's Quadlet File"
    ln -sf "${SELFHOST_ROOT_DIR:-$HOME/selfhost}/apps/$folder/$1.container" .

    if systemctl --user cat "$1.service" >/dev/null 2>&1; then
        echo "-> Stopping '$1' Container's Previous Service"
        systemctl --user stop "$1.service"
    else
        echo "-> No previous '$1' service is installed"
    fi
    echo "-> Reloading Systemctl Daemon"
    systemctl --user daemon-reload
    echo "-> Starting '$1' Container's Service"
    systemctl --user start "$1.service"
}
