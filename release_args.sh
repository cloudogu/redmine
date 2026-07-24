# shellcheck disable=SC1090
source "$(pwd)/build/make/release_functions.sh"

wait_for_ok "Please make sure that air-gapped environments were sufficiently tested. See docs/development/test_air-gapped_en.md"
