.PHONY: validate test install-user install-project uninstall-user

validate:
	python3 scripts/validate_skill.py SKILL.md

test: validate
	bash tests/test_installers.sh

install-user:
	bash ./install.sh --scope user

install-project:
	@test -n "$(PROJECT_DIR)" || (echo "PROJECT_DIR is required" >&2; exit 1)
	bash ./install.sh --scope project --project-dir "$(PROJECT_DIR)"

uninstall-user:
	bash ./uninstall.sh --scope user
