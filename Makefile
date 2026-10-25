DEV_DB := $(HOME)/Library/Application Support/Ledgerly Development/finance.sqlite
.DEFAULT_GOAL := dev

.PHONY: new dev clean app seed

new: clean
	swift run

dev:
	swift run

seed:
	swift run -c debug Finance --seed-development-data

app:
	@mkdir -p dist
	swift build -c release
	@set -eu; \
	build_dir="$$(swift build -c release --show-bin-path)"; \
	app_dir="dist/Finance.app/Contents"; \
	mkdir -p "$$app_dir/MacOS" "$$app_dir/Resources"; \
	cp "$$build_dir/Finance" "$$app_dir/MacOS/Finance"; \
	cp Packaging/Info.plist "$$app_dir/Info.plist"; \
	for bundle in "$$build_dir/Finance_FinanceApp.bundle" "$$build_dir/GRDB_GRDB.bundle"; do \
		ditto "$$bundle" "$$app_dir/Resources/$$(basename "$$bundle")"; \
	done; \
	codesign --force --sign - dist/Finance.app; \
	echo "Created dist/Finance.app. Drag it into Applications to install."

clean:
	rm -f "$(DEV_DB)" "$(DEV_DB)-shm" "$(DEV_DB)-wal" "$(DEV_DB)-journal"
