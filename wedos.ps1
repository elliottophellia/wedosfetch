#VERSION 1.0.0
#AUTHOR Reidho Satria <me@rei.my.id>
#PROJECTURI https://github.com/elliottophellia/wedosfetch
#LICENSEURI https://github.com/elliottophellia/wedosfetch/blob/main/LICENSE

# Clean up the screen
#Clear-Host

# Get Username in Uppercase
$currentUser = $env:USERNAME.ToUpper() 

# Get Hostname in Uppercase
$computerName = $env:COMPUTERNAME.ToUpper()

# Get Operating System Information
$osVer = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName

# Get Kernel Information
$kernel = (Get-WmiObject Win32_OperatingSystem).Version

# Get Uptime Information
$uptime = (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime
$uptimeString = "{0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

# Get DE/WM Information
$getDeWm = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon').Shell
$deWm = $getDeWm.Substring(0, 1).ToUpper() + $getDeWm.Substring(1).ToLower().Replace('.exe', '')

# Get Screen Resolution
Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$resolution = "$($screen.Width) x $($screen.Height)"

# Get Terminal & Terminal Font Information
if ($env:WT_SESSION) {
    $terminal = "Windows Terminal"
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    $wtSettings = Get-Content $wtSettingsPath | ConvertFrom-Json
    if ($null -ne $wtSettings.profiles.defaults.font -and $wtSettings.profiles.defaults.font.face) {
        $terminalFont = $wtSettings.profiles.defaults.font.face
    }
    else {
        $terminalFont = "Cascadia Mono"
    }
}
elseif ($psISE) {
    $terminal = "PowerShell ISE"
    $terminalFont = (Get-ItemProperty 'HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe').FaceName.ToString()
}
elseif ($host.Name -eq 'ConsoleHost') {
    $terminal = "PowerShell Console"
    $terminalFont = (Get-ItemProperty 'HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe').FaceName.ToString()
}
elseif ($host.Name -eq 'Visual Studio Code Host') {
    $terminal = "Visual Studio Code Host"
    if (Test-Path $env:APPDATA\Code\User\settings.json) {
        $vsCodeSettingsPath = Get-Content $env:APPDATA\Code\User\settings.json | ConvertFrom-Json
    }
    elseif (Test-Path $env:APPDATA\Cursor\User\settings.json) {
        $vsCodeSettingsPath = Get-Content $env:APPDATA\Cursor\User\settings.json | ConvertFrom-Json
    }
    if ($null -ne $vsCodeSettingsPath.'editor.fontFamily') {
        $terminalFont = $vsCodeSettingsPath.'editor.fontFamily'
    }
    else {
        $terminalFont = "Consolas, Courier New, monospace"
    }
}
else {
    $terminal = "Unknown Terminal"
    $terminalFont = "Unknown Terminal Font"
}

# Get PowerShell Version
$psVersion = $PSVersionTable.PSVersion 
$shell = "PowerShell $psVersion"

# Get Disk Information
$diskLines = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $used = ($_.Size - $_.FreeSpace) / 1GB -as [int]
    $free = $_.FreeSpace / 1GB -as [int]
    "$($_.DeviceID) Used: $used GB, Free: $free GB"
}

# Formatting Disk Information for Display with Proper Alignment
$diskInfo = $diskLines -join "`n|             | " | Out-String

# Trimming the trailing newline to prevent formatting issues
$diskInfo = $diskInfo.TrimEnd()

# Get CPU Information
$cpuModel = (Get-WmiObject Win32_Processor).Name

# Get GPU Information
$gpuModel = (Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty Name) -join ', '

# Get RAM Information
$os = Get-WmiObject Win32_OperatingSystem
$totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRam = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRam = $totalRam - $freeRam
$ramInfo = "Total: $totalRam GB, Used: $usedRam GB, Free: $freeRam GB"

# Get Local IP
# Credit to : https://github.com/lptstr/winfetch/blob/8d4f687b5e212f276c63ff26f09bee218b65d9b6/winfetch.ps1#L1368
foreach ($ni in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
    # Get the IP information of each adapter
    $properties = $ni.GetIPProperties()
    # Check if the adapter is online, has a gateway address, and the adapter does not have a loopback address
    if ($ni.OperationalStatus -eq 'Up' -and !($null -eq $properties.GatewayAddresses[0]) -and !$properties.GatewayAddresses[0].Address.ToString().Equals("0.0.0.0")) {
        # Check if adapter is a WiFi or Ethernet adapter
        if ($ni.NetworkInterfaceType -eq "Wireless80211" -or $ni.NetworkInterfaceType -eq "Ethernet") {
            foreach ($ip in $properties.UnicastAddresses) {
                if ($ip.Address.AddressFamily -eq "InterNetwork") {
                    if (!$local_ip) { $local_ip = $ip.Address.ToString() }
                }
            }
        }
    }
}

# Get Public IP
if (Invoke-RestMethod https://ip.rei.my.id -ErrorAction SilentlyContinue) {
    $public_ip = (Invoke-RestMethod https://ip.rei.my.id).RequestResult.query
} else {
    $public_ip = "0.0.0.0"
}

# Get Color Blocks
function Show-ColorBlocks {
    $colors = [enum]::GetNames([System.ConsoleColor])
    $colorCount = 0
    foreach ($color in $colors) {
        if ($colorCount -eq 0) {
            Write-Host "                          " -NoNewline
        }
        $bgColor = $color
        if ($color -eq 'Black') { $fgColor = 'White' } else { $fgColor = 'Black' }
        Write-Host "    " -ForegroundColor $fgColor -BackgroundColor $bgColor -NoNewline
        $colorCount++
        if ($colorCount -eq 8) {
            Write-Host ""
            $colorCount = 0
        }
    }
    if ($colorCount -ne 0) {
        Write-Host ""
    }
}

# Banner
$banner = @"
                _,._      {0}@{1} ~ $local_ip / $public_ip
             __.'   _)      
            <_,)'.-"a\    OS            | {2}
              /' (    \   KERNEL        | {3}
  _.-----..,-'   ('"--^   UPTIME        | {4}
 //              |        SHELL         | {5}
(|   ,;      ,   |        DE/WM         | {6}
  \   ;.----/  ,/         RESOLUTION    | {7}
   ) // /   | |\ \        TERMINAL      | {8}
   \ \\,\   | |/ /        TERMINAL FONT | {9}
   ) // /   | |\ \        CPU MODEL     | {12}
   \ \\,\   | |/ /        GPU MODEL     | {13}
    \ \\ \  | |\/         RAM INFO      | {14}
     '" '"  '" '          DISK INFO     | {10}
                                        | {11}
"@

# Displaying all
Write-Host ($banner -f $currentUser, $computerName, $osVer, $kernel, $uptimeString, $shell, $deWm, $resolution, $terminal, $terminalFont, $diskLines[0], ($diskLines[1..($diskLines.Count - 1)] -join "`n                                        | "), $cpuModel, $gpuModel, $ramInfo)
Show-ColorBlocks
Write-Host ""