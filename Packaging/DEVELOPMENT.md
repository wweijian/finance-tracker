Finance development builds (`make dev` or `swift run`) use:

    ~/Library/Application Support/Ledgerly Development/finance.sqlite

Release builds (`make app`) use the existing personal database:

    ~/Library/Application Support/Ledgerly/finance.sqlite

Feedback files are separated in the same folders. Neither build adds sample data on launch.
The original Ledgerly folder names are retained so existing data stays available after
renaming the app. `make app` creates `dist/Finance.app`; the app's bundle identifier also
stays the same to preserve macOS preferences.

Run `make seed` explicitly to create fictional SGD transactions in the development database.
Dates span the day the command runs back through three calendar months, inclusive, using
the Mac's local calendar date. The samples include daily spending, weekly groceries,
salary, interest, bills, subscriptions, and investments. Rerunning the command preserves
existing rows and edits, adding only missing samples.

`make clean` removes only the development database. `make new` clears it and launches
development without samples. To start over with fresh samples, quit the development app,
run `make clean`, then `make seed` and `make dev`.
