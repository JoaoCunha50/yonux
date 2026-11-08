# Contributing

Open pull requests against `development`.
Use a draft PR while work is in progress and mark it ready when you want review.
The CI checks this destination, `main` accepts promotions from this repository's
`development` or temporary `release/*` branches.

`main` is the default branch and contains the stable line. Maintainers promote
changes from `development` to `main` for a release. Temporary release branches
are available when necessary; versions and release candidates are discretionary.
Feature PRs can be squash merged.

## Development

Run `./dev.sh` from the checkout. It runs `./install.sh` (re-links the config,
rebuilds `yonux` and `yonux-ipc` into `~/.local/bin`, materializes) and restarts
the shell in the foreground with its log on the terminal; Ctrl+C stops it.
`./dev.sh --build` does the same without touching the running shell.

Files under `~/.config/yonux/matugen/` are symlinks into the checkout, so template
edits apply on the next palette change. Run `./dev.sh --build` again after adding
a file there or changing Go code.

## Checks

The required GitHub check is named **CI**. Its steps run on one runner and check:

- Go formatting, vet, tests and build for `yonux/cli` and `yonux/shell/ipc`.
- Pull request destination.
- Nix flake evaluation.
- ShellCheck for shell scripts.
- QML checking with the pinned Nix tooling. Syntax errors fail; existing semantic
  and tooling warnings remain advisory. This does not test a graphical session.

Fork PRs run the checks without project secrets. Maintainers may need to approve
the workflow run in GitHub before it starts. The contributor's code is not run
by a privileged `pull_request_target` workflow.
