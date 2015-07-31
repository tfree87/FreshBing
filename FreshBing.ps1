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
$rssUrl = "http://www.bing.com/HPImageArchive.aspx?format=xml&idx=0&n=1&mkt=en-AU" 

if (Test-Path $settingsFile) {
    $settings = [xml](Get-Content $settingsFile)
	$refreshIntervalDays = $settings.settings.refreshIntervalDays
	$rssUrl = $settings.settings.rssUrl
}

$runFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "LastRun.xml"

[System.Net.WebClient] $wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
 
$feed = [xml]$wc.DownloadString($rssUrl)
$base = [Environment]::GetFolderPath("MyPictures")
$selectedUrl = ""
$selectedFile = $base + "\background.jpg"
$oldFile = ""

if (!$feed) {
    Write-Error "Feed download failed - try again later."
    Return
}


$selectedUrl = "http://www.bing.com" + $feed.images.image.url

$selectedUrl = $selectedUrl.Substring(0, $selectedUrl.LastIndexOf("_"))

$selectedUrl += "_1920x1080.jpg"

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

[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    
[Drawing.Image] $image = [Drawing.Image]::FromFile($selectedFile)
[Drawing.Graphics] $g = [System.Drawing.Graphics]::FromImage($image)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

$font = [Drawing.Font]::new("Arial", 8)
$brush = [System.Drawing.Brushes]::White
$point =  [Drawing.PointF]::new(0, $image.Height - 16)

$g.DrawString($feed.images.image.copyright, $font, $brush, $point)

$bmpFile = [System.IO.Path]::ChangeExtension($selectedFile, ".bmp")
$image.Save($bmpFile) #, "Bmp")
$g.Dispose()
$image.Dispose()
    
[FreshBing.UnsafeNativeMethods]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $bmpFile, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE)

Set-ItemProperty -path "HKCU:\Control Panel\Desktop\" -name WallpaperStyle -value 2
Set-ItemProperty -path "HKCU:\Control Panel\Desktop\" -name TileWallpaper -value 0

# Save this run time
Get-Date | Export-Clixml $runFile
