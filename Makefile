DB := $(HOME)/Library/Application Support/Ledgerly/finance.sqlite

dev:
	rm -f "$(DB)"
	swift run

clean:
	rm -f "$(DB)" "$(DB)-shm" "$(DB)-wal"
