function Logo_Menu {
    param(
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    $oldColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color

    $ascii = @"
    
                                                   _                        _
       _  _      /\ /\                            ( ) ___,      _ __    _  ( ) _ __                  ___
     _| || |_    | '_ \  ____ __      __ ___  _ __ \||  _'\  _ | '_ \  | | |/ | '_ \  /\/\   ___    |__ \
    |_  ..  _|   | |_) |/ _//\\ \ /\ / // _ \| '__|  | | | || || | | |/ __|   | |_) |/  _ \ / __|     / /
    |_      _|   | .__/| (//) |\ V  V /|  __/| |     | |_/ || || | | |\__ \   | .__/|  ___/| (__     |_|
      |_||_|     |_|    \//__/  \_/\_/  \___||_|     |____/ |_||_| |_||___/   |_|    \____| \___|  
                                         | |                (_)        |_|                           (_)      Version 1.8.5

                                        
"@ -split "`n"

    foreach ($line in $ascii) { Write-Host $line }

    $Host.UI.RawUI.ForegroundColor = $oldColor
}

Logo_Menu -Color Red
