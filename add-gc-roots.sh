#! /usr/bin/env bash
set -euo pipefail

: "${DRY_RUN:=0}"

flake_path=$(realpath "${1:-$(pwd)}")
flake_dirname=$(basename "$flake_path")

flake_drvs_expr_file=$(realpath "$(dirname "${BASH_SOURCE[0]}")/flake-derivations.nix")
flake_drvs_expr="import $flake_drvs_expr_file builtins.currentSystem \"$flake_dirname\""

readarray -t flake_drvs < <(
	nix eval --option pure-eval false --impure --json \
		--override-flake "$flake_dirname" "$flake_path" \
		--expr "$flake_drvs_expr" \
		| jq -r '.[]'
)

for store_path in "${flake_drvs[@]}"; do
	drv_name=$(basename "$store_path")
	if [ "$DRY_RUN" -eq 1 ]; then
		echo "/tmp/$drv_name"
	else
		nix-store --add-root "/tmp/$drv_name" --realise "$store_path"
	fi
done
