.PHONY: validate test install-user install-project uninstall-user

validate:
	python3 scripts/validate_skill.py SKILL.md

test: validate
	bash tests/test_installers.sh

install-user:
	./install.sh --scope user

install-project:
	@test -n "$(PROJECT_DIR)" || (echo "PROJECT_DIR is required" >&2; exit 1)
	./install.sh --scope project --project-dir "$(PROJECT_DIR)"

uninstall-user:
	./uninstall.sh --scope user
