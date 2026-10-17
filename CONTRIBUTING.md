# Contributing to Scribo

Thanks for your interest in improving Scribo! Contributions are welcome.

## How to contribute

Scribo is maintained by [@hendro-steven](https://github.com/hendro-steven).
Because it's a public repo, you don't need write access — contribute via a fork:

1. **Fork** this repository to your own account.
2. **Clone** your fork and create a branch:
   ```bash
   git checkout -b feature/my-change
   ```
3. Make your change. Keep the style consistent with the surrounding code.
4. **Build and test it locally** to make sure it compiles, runs, and passes:
   ```bash
   swift build          # or: ./make-app.sh && open .build/Scribo.app
   swift test           # run the unit tests
   ```
   If you change logic in `ScriboCore`, please add or update tests in
   `Tests/ScriboCoreTests`.
5. **Push** to your fork and **open a Pull Request** against `main`.

## What happens next

- **CI** builds your PR and runs `swift test` automatically — both must pass
  before merging.
- The **maintainer reviews** every PR. Approval from the code owner is required
  to merge (see [`.github/CODEOWNERS`](.github/CODEOWNERS)).
- `main` is protected: no direct pushes, no force-pushes, no branch deletion.

## Releases

Releases are **maintainer-only**. Tagging (`vX.Y.Z`) and publishing to GitHub
Releases is restricted to the maintainer and gated behind a protected
environment. Please don't include version bumps or release tags in PRs.

## Good first contributions

See the **Roadmap ideas** in the [README](README.md) — e.g. snapshot-to-image,
configurable hot keys, or an on-screen tool HUD.
