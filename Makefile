DB := $(HOME)/Library/Application Support/Ledgerly/finance.sqlite

new:
	rm -f "$(DB)"
	swift run

dev:
	swift run

clean:
	rm -f "$(DB)" "$(DB)-shm" "$(DB)-wal"
