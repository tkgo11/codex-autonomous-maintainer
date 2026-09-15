.PHONY: validate checksums checksums-check test install-user install-user-standalone install-user-both install-project install-project-standalone install-project-both uninstall-user uninstall-user-standalone uninstall-user-both

validate:
	python3 scripts/validate_skill.py SKILL.md
	python3 scripts/validate_skill.py standalone/SKILL.md
	python3 scripts/validate_release.py

checksums:
	python3 scripts/validate_checksums.py --write

checksums-check:
	python3 scripts/validate_checksums.py

test: validate checksums-check
	bash tests/test_installers.sh
	@if command -v pwsh >/dev/null 2>&1; then \
		pwsh -NoLogo -NoProfile -NonInteractive -File tests/test_installers.ps1; \
	else \
		echo "pwsh not found; skipping PowerShell installer tests"; \
	fi

install-user:
	bash ./install.sh --scope user

install-user-standalone:
	bash ./install.sh --variant standalone --scope user

install-project:
	@test -n "$(PROJECT_DIR)" || (echo "PROJECT_DIR is required" >&2; exit 1)
	bash ./install.sh --scope project --project-dir "$(PROJECT_DIR)"

install-user-both:
	bash ./install.sh --variant both --scope user

install-project-standalone:
	@test -n "$(PROJECT_DIR)" || (echo "PROJECT_DIR is required" >&2; exit 1)
	bash ./install.sh --variant standalone --scope project --project-dir "$(PROJECT_DIR)"

install-project-both:
	@test -n "$(PROJECT_DIR)" || (echo "PROJECT_DIR is required" >&2; exit 1)
	bash ./install.sh --variant both --scope project --project-dir "$(PROJECT_DIR)"

uninstall-user:
	bash ./uninstall.sh --scope user

uninstall-user-standalone:
	bash ./uninstall.sh --variant standalone --scope user

uninstall-user-both:
	bash ./uninstall.sh --variant both --scope user
