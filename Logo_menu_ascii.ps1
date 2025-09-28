function Logo_Menu {
    param(
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    $oldColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color

    $ascii = @"
 _ __                               ___,                                _ __
| '_ \  ___ __      __ ___  _ __   |  _'\  _ __   ___   (_) _ __   ___ | '_ \  ___   ___
| |_) |/ _ \\ \ /\ / // _ \| '__|  | | | || '_ \ / __|  | || '_ \ / __|| |_) |/ _ \ / __|
| .__/| (_) |\ V  V /|  __/| |     | |_/ || | | |\__ \  | || | | |\__ \| .__/|  __/| (__ 
|_|    \___/  \_/\_/  \___||_|     |____/ |_| |_||___/  |_||_| |_||___/|_|    \___| \___|
"@ -split "`n"

    foreach ($line in $ascii) { Write-Host $line }

    $Host.UI.RawUI.ForegroundColor = $oldColor
}

Logo_Menu -Color Yellow

# (letras)https://github.com/EliteLoser/WriteAscii/blob/master/letters.xml
