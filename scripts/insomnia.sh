#!/bin/bash
# Insomnia is now Lidocaine. This keeps the old "insomnia" command and old
# links working; everything runs the same Lidocaine script.
exec /bin/bash "$(dirname "$(realpath "$0")")/lidocaine.sh" "$@"
