#!/usr/bin/env bash
# Checks that all tool names in mise config files are prefixed with a backend.
# (e.g. "aqua:jdx/hk" instead of bare "hk")
#
# Supports all key forms, including:
#   hk = "latest"                  ← bare (bad)
#   "aqua:jdx/hk" = "latest"      ← inline with backend (good)
#   [tools."http:flutter"]         ← table-header style (good)
#   [tools.node]                   ← table-header style, bare (bad)
#
# To suppress the check for a specific tool, add an inline comment:
#   hk = "latest"  # mise-lint: disable
#   [tools.node]   # mise-lint: disable
#
# Requires: yq v4+ (https://github.com/mikefarah/yq) with TOML support
#
# Exit 0 = all tools have explicit backends
# Exit 1 = one or more bare tool names found

set -eou pipefail

BACKENDS="core aqua asdf cargo conda dotnet forgejo gem github gitlab go http npm packslip pipx pkgx spm ubi vfox"

has_backend() {
	tool="$1"
	for b in $BACKENDS; do
		case "$tool" in "$b":*) return 0 ;; esac
	done
	return 1
}

# Returns 0 (true) if the given tool key has a "# mise-lint: disable" comment
# in the raw file. Handles both inline-assignment and table-header forms:
#   hk = "latest" # mise-lint: disable
#   [tools.hk]    # mise-lint: disable
is_disabled() {
	file="$1"
	tool="$2"
	# Escape dots and special chars for use in grep basic regex
	escaped=$(printf '%s' "$tool" | sed 's/[.[\*^$]/\\&/g')
	# Match either:
	#   <tool> = ...  # mise-lint: disable     (assignment form)
	#   [tools.<tool>]  # mise-lint: disable   (table-header form, quoted or bare)
	grep -qE \
		"(^[[:space:]]*\"?${escaped}\"?[[:space:]]*=|\\[tools(\\.\"${escaped}\"|[.]${escaped})\\])[^#]*#[[:space:]]*mise-lint:[[:space:]]*disable" \
		"$file"
}

failed=0

for file in "$@"; do
	if [ ! -f "$file" ]; then
		printf 'mise-tool-backend-lint: file not found: %s\n' "$file" >&2
		failed=1
		continue
	fi

	tool_keys=$(yq --input-format toml --output-format tsv '.tools | keys | .[]' "$file" 2>/dev/null) || {
		printf 'mise-tool-backend-lint: failed to parse "%s" — is it valid TOML?\n' "$file" >&2
		failed=1
		continue
	}

	[ -z "$tool_keys" ] || [ "$tool_keys" = "null" ] && continue

	for tool in $tool_keys; do
		[ -z "$tool" ] && continue
		if ! has_backend "$tool"; then
			if is_disabled "$file" "$tool"; then
				continue
			fi
			printf '%s: tool "%s" is missing an explicit backend prefix (e.g. "aqua:%s")\n' \
				"$file" "$tool" "$tool"
			failed=1
		fi
	done
done

exit $failed
