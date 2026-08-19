# DBeaver Join Lines

Adds Eclipse's native **Join Lines** command to the **Format** submenu of the DBeaver SQL editor context menu.

This project does not reimplement the editor action. It exposes the native Eclipse command:

```text
org.eclipse.ui.edit.text.join.lines
```

inside DBeaver's dynamically created `Format` context submenu.

## Why?

DBeaver includes the underlying Eclipse `Join Lines` command, but it is not exposed in the SQL editor's **Format** context menu by default.

This small plugin adds it there.

## Installation

### Portable package

Download or build the portable ZIP, extract it, close DBeaver and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

If DBeaver is installed in a custom location:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -DBeaverHome "C:\Path\To\DBeaver"
```

After installation:

```text
SQL editor
└── Right click
    └── Format
        └── Join Lines
```

The extracted installer folder can be deleted after a successful installation.

### Uninstall

The plugin can be removed from DBeaver through:

```text
Help
→ About DBeaver
→ Installation Details
→ Installed Software
→ DBeaver Join Lines
→ Uninstall
```

or with:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## Keyboard shortcut

The plugin does not define or override a keyboard shortcut.

Eclipse/DBeaver may already associate a shortcut with `Join Lines`. You can customize it in:

```text
Window
→ Preferences
→ User Interface
→ Keys
```

Search for `Join Lines`.

## Build

Requirements:

- Windows PowerShell
- A local DBeaver installation containing Eclipse p2 publisher/director components
- DBeaver closed during the build

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

If DBeaver is not automatically detected:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -DBeaverHome "C:\Path\To\DBeaver"
```

The distributable package is created under:

```text
dist\DBeaverJoinLines-1.0.0-portable.zip
```

## How it works

The plugin contributes the existing Eclipse command:

```text
org.eclipse.ui.edit.text.join.lines
```

to DBeaver's SQL editor submenu:

```text
popup:format?after=additions
```

The plugin is packaged as an Eclipse feature and published as a local p2 repository. The portable installer uses the Eclipse p2 Director bundled with DBeaver.

## Project structure

```text
.
├── plugin/
│   ├── plugin.xml
│   └── META-INF/
│       └── MANIFEST.MF
├── feature/
│   └── feature.xml
├── category.xml
├── build.ps1
├── install.ps1
├── uninstall.ps1
├── README-INSTALL.txt
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

## Compatibility

Developed and verified with DBeaver Community **26.1.5** on Windows.

Because the plugin relies on Eclipse UI command IDs and DBeaver's `format` menu contribution ID, future DBeaver releases could require an update if those internals change.

## Author

**Ruben Carracedo**  
GitHub: [@jabaruben](https://github.com/jabaruben)

## License

MIT License — Copyright © 2026 Ruben Carracedo.

DBeaver and Eclipse are trademarks of their respective owners. This project is an independent community extension and is not affiliated with or endorsed by DBeaver Corp. or the Eclipse Foundation.
