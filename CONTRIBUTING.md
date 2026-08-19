# Contributing to DBeaver Join Lines

Thanks for considering a contribution.

## Ways to contribute

- Report a bug.
- Suggest an improvement.
- Improve documentation.
- Test the plugin with other DBeaver versions.
- Submit a pull request with a fix or enhancement.

## Development workflow

1. Fork the repository.
2. Create a branch from `main`.
3. Make your changes.
4. Run the validation checks and, when relevant, build the portable package locally.
5. Open a pull request against `main`.

Example:

```bash
git checkout -b fix/short-description
```

## Building locally

The build currently requires Windows PowerShell and a local DBeaver installation containing the Eclipse p2 publisher/director components.

Close DBeaver, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

For a specific version:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 1.0.1
```

If DBeaver cannot be detected automatically:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -DBeaverHome "C:\Path\To\DBeaver"
```

## Pull requests

Please keep pull requests focused. Explain:

- what changed;
- why the change is useful;
- how it was tested;
- which DBeaver version was used for testing, when relevant.

Do not include generated `build/` or `dist/` content in commits.

## Compatibility changes

The plugin relies on Eclipse's native command `org.eclipse.ui.edit.text.join.lines` and DBeaver's SQL editor `format` menu contribution ID. If a DBeaver update changes either integration point, please include the tested DBeaver version and the relevant discovery details in the pull request.

## Releases

Release tags (`v*`) are maintained by the project owner. Contributors should not change release metadata or version tags unless explicitly requested as part of a contribution.

## License

By contributing, you agree that your contribution will be licensed under the project's MIT License.
