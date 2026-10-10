# river-ui

macOS Flutter dashboard for River: logs, traces and metrics pages over `river-query-api`.

```bash
mise run dev:setup        # point xcode-select at Xcode (once)
mise run dev:run          # run on macOS
mise run dev:api-client   # regenerate lib/api/generated from openapi.json
mise run ci:flutter-test
```

`openapi.json` is the contract published by [river-query](https://github.com/bsterligov/river-query).
Specs and agent context live in [river-spec](https://github.com/bsterligov/river-spec).
