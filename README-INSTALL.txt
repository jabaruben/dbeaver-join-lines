DBeaver Join Lines 1.0.0
Copyright (c) 2026 Ruben Carracedo
Licensed under the MIT License
https://github.com/jabaruben/dbeaver-join-lines

INSTALL
=======
1. Extract the complete ZIP.
2. Close DBeaver.
3. Open PowerShell in this folder.
4. Run:

   powershell -ExecutionPolicy Bypass -File .\install.ps1

Custom DBeaver location:

   powershell -ExecutionPolicy Bypass -File .\install.ps1 -DBeaverHome "C:\Path\To\DBeaver"

After installation:
   SQL editor -> Right click -> Format -> Join Lines

The extracted folder can be deleted after successful installation.

UNINSTALL
=========
Use DBeaver:
   Help -> About DBeaver -> Installation Details -> Installed Software

or run:
   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
