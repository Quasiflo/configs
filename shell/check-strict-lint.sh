#!/usr/bin/env bash
# Checks that all parsed files include some form of "strict mode", ie "set -eou pipefail"
set -euo pipefail

status=0
for f in "$@"; do
	# require errexit (-e somewhere in a `set -...e...` line)
	if ! grep -qE '^\s*set\s+-[a-zA-Z]*e' "$f"; then
		echo "$f: missing 'set -e' (errexit)"
		status=1
	fi
	# require pipefail enabled via a `set` command (combined, standalone, or split flags)
	if ! grep -qE '^\s*set\s+-[a-zA-Z]*o[a-zA-Z]*\s+pipefail' "$f" &&
		! grep -qE '^\s*set\s+(-[^[:space:]]+\s+)*-o\s+pipefail' "$f"; then
		echo "$f: missing 'pipefail'"
		status=1
	fi
done

exit $status
