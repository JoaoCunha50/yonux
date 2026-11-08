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

Run `./dev.sh` from the clone to run the shell straight from it, in the
foreground with its log on the terminal. QML edits reload live; for Go changes,
press Ctrl+C and run it again. It builds `yonux` and `yonux-ipc` into a temp
dir and composes Matugen there from the clone and your real `user_preferences`;
it installs and records nothing, and removes the temp dir on exit.

While it runs, the installed shell is stopped, and it is started again on exit
if it was running. `dev.sh` is not a sandbox: it uses your real session and
preferences, and what you change in it (settings, shortcuts, theme) stays after
exit. Stop it from another terminal with
`qs kill -p <clone>/yonux/shell/quickshell`. If it is killed outright
(`SIGKILL`), start the installed shell again with `qs -c yonux -d`.

To install the clone for normal use, run `./install.sh`
(`yonux dev-apply --from <clone root>`); see the README.

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
