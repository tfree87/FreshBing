# FreshBing
# https://github.com/ndabas/FreshBing
#
# Copyright 2012-2013 Nikhil Dabas
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.

Param([switch]$autorun)

$settingsFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "Settings.xml"

# Default values, if a settings file does not exist
$refreshIntervalDays = 1
$rssUrl = "http://themeserver.microsoft.com/default.aspx?p=Bing&c=Desktop&m=en-US" 

if (Test-Path $settingsFile) {
    $settings = [xml](Get-Content $settingsFile)
    $refreshIntervalDays = $settings.settings.refreshIntervalDays
    $rssUrl = $settings.settings.rssUrl
}

$runFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "LastRun.xml"

# On autorun, only run if it's been more than a day since the last run.
# We actually check for a 23-hour gap because scheduled tasks are not exactly
# precise.
if ($autorun -and (Test-Path $runFile)) {
    $lastRun = Import-Clixml $runFile
    $totalHours = 24 * ($refreshIntervalDays - 1) + 23
    if (((Get-Date) - $lastRun).TotalHours -lt $totalHours) {
        Write-Warning "Less than $refreshIntervalDays day(s) since the last run - exiting."
        Return
    }
}

$feed = [xml](New-Object System.Net.WebClient).DownloadString($rssUrl)
$base = [Environment]::GetFolderPath("MyPictures")
$selectedUrl = ""
$selectedFile = ""
$oldFile = ""

if (!$feed) {
    Write-Error "Feed download failed - try again later."
    Return
}

# Run through the feed, and find the oldest file that we haven't downloaded yet.
foreach ($item in $feed.rss.channel.item) {
    $url = New-Object System.Uri($item.enclosure.url)
    $file = [System.Uri]::UnescapeDataString($url.Segments[-1])
    $path = Join-Path $base $file
    
    # We have this file, so we need to download the previous file and delete this one
    if (Test-Path $path) {
        $oldFile = $path
        Break
    }
    $selectedUrl = $url
    $selectedFile = $path
}

if (!$selectedUrl) {
    Write-Host "Nothing to download - we already have the newest file."
    Return
}

Write-Host "Downloading $selectedUrl -> $selectedFile"
(New-Object System.Net.WebClient).DownloadFile($selectedUrl, $selectedFile)

if (!(Test-Path $selectedFile)) {
    Write-Error "Download failed - try again later."
    Return
}

Add-Type -Namespace FreshBing -Name UnsafeNativeMethods -MemberDefinition @"
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
"@
$SPI_SETDESKWALLPAPER = 20
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDWININICHANGE = 0x02
$result = [FreshBing.UnsafeNativeMethods]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $selectedFile, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE)
# This could fail on Windows XP because it does not support jpg wallpapers natively
if ($result -ne 1) {
    # Convert the file to a bmp and set that as wallpaper
    [Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    
    $image = [Drawing.Image]::FromFile($selectedFile)
    $bmpFile = [System.IO.Path]::ChangeExtension($selectedFile, ".bmp")
    $image.Save($bmpFile, "Bmp")
    $image.Dispose()
    
    [FreshBing.UnsafeNativeMethods]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $bmpFile, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE)
}
Set-ItemProperty -path "HKCU:\Control Panel\Desktop\" -name WallpaperStyle -value 2
Set-ItemProperty -path "HKCU:\Control Panel\Desktop\" -name TileWallpaper -value 0

if ($oldfile -and (Test-Path $oldFile)) {
    Remove-Item $oldFile
    Write-Host "Deleting $oldFile"
    
    $bmpFile = [System.IO.Path]::ChangeExtension($oldFile, ".bmp")
    if (Test-Path $bmpFile) {
        Remove-Item $bmpFile
        Write-Host "Deleting $bmpFile"
    }
}

# Save this run time
Get-Date | Export-Clixml $runFile
