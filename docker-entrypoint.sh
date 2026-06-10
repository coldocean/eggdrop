#!/usr/bin/env bash
# Entrypoint for the WUNDERkind Eggdrop bot on Railway.
#
# Fills runtime values into eggdrop.conf from environment variables and writes
# the NickServ password to a file the TCL reads (kept out of the image/repo).
#
# Expected env vars (set as Railway service variables):
#   IRC_SERVER          uplink host   (default: yamanote.proxy.rlwy.net)
#   IRC_PORT            uplink port   (default: 52947)
#   NICKSERV_PASS       password to IDENTIFY the bot's nick to NickServ
#   OWNER_PASS          partyline password seeded for deemah & funt (optional)
#   PORT                Railway-provided port for the DCC/telnet partyline
set -e

EGG=/opt/eggdrop
CONF="$EGG/eggdrop.conf"
DATA="$EGG/data"

mkdir -p "$DATA" "$EGG/logs"

IRC_SERVER="${IRC_SERVER:-yamanote.proxy.rlwy.net}"
IRC_PORT="${IRC_PORT:-52947}"
DCC_PORT="${PORT:-3333}"

echo ">> WUNDERkind starting: uplink ${IRC_SERVER}:${IRC_PORT}, DCC port ${DCC_PORT}"

# Substitute the placeholders in the config.
sed -i \
    -e "s/__IRC_SERVER__/${IRC_SERVER}/g" \
    -e "s/__IRC_PORT__/${IRC_PORT}/g" \
    -e "s/__DCC_PORT__/${DCC_PORT}/g" \
    "$CONF"

# Write the NickServ password out for wunderbar.tcl (if provided).
if [ -n "${NICKSERV_PASS:-}" ]; then
    printf '%s' "$NICKSERV_PASS" > "$DATA/nickserv.pass"
    chmod 600 "$DATA/nickserv.pass"
    echo ">> NickServ password installed."
fi

cd "$EGG"

# First boot: there is no userfile yet. Create the bot with -m so it makes a
# fresh userfile; owners then claim ownership with `/msg WUNDERkind hello`.
# On later boots the userfile in the persisted volume is reused.
if [ ! -f "$DATA/WUNDERkind.user" ]; then
    echo ">> No userfile found — creating one (-m). Claim ownership in-channel:"
    echo "   /msg WUNDERkind hello   (first owner)  then  .help"
    exec "$EGG/eggdrop" -mn "$CONF"
else
    echo ">> Userfile present — normal start."
    exec "$EGG/eggdrop" -n "$CONF"
fi
