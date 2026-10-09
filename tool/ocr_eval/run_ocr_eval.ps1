<#
.SYNOPSIS
  Evaluates the receipt OCR pipeline on real photos, on any connected
  Android device or emulator, with one command.

.DESCRIPTION
  1. Checks the SHA-256 of ground_truth.csv against the locked value and
     stops if it differs (the answers must not change between runs).
  2. Copies ground_truth.csv and the photos it lists to the app's external
     files folder on the device (ocr_eval/).
  3. Runs integration_test/ocr_eval_test.dart on that device.
  4. Pulls report.json and report.md into <DataDir>\reports\<time>_<device>\
     (outside the repository) and removes the photos from the device.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1 -DeviceId R58M12ABCDE
#>
param(
  [string]$DataDir = 'D:\receipts-test',
  [string]$ExpectedSha256 = '0ec9054112e46ecebf22f87b5d12dec588c9aea5c52eacad37f2ae134d03ecc0',
  [string]$DeviceId = '',
  [string]$Flutter = 'flutter',
  [switch]$KeepOnDevice
)
$ErrorActionPreference = 'Stop'
$package = 'vn.edu.vku.vku_expense_ocr'
$remote = "/sdcard/Android/data/$package/files/ocr_eval"
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Invoke-Native([string]$exe, [string[]]$arguments) {
  & $exe @arguments
  if ($LASTEXITCODE -ne 0) { throw "$exe $($arguments -join ' ') failed ($LASTEXITCODE)" }
}

# --- 1. Locked ground truth -------------------------------------------------
$csv = Join-Path $DataDir 'ground_truth.csv'
if (-not (Test-Path $csv)) { throw "Not found: $csv" }
$hash = (Get-FileHash $csv -Algorithm SHA256).Hash.ToLowerInvariant()
if ($hash -ne $ExpectedSha256.ToLowerInvariant()) {
  Write-Host "STOP: ground_truth.csv hash $hash does not match the locked $ExpectedSha256" -ForegroundColor Red
  exit 2
}
Write-Host "ground_truth.csv hash OK ($hash)"

# --- 2. Device ----------------------------------------------------------------
$adb = 'adb'
if ($env:ANDROID_HOME -and (Test-Path "$env:ANDROID_HOME\platform-tools\adb.exe")) {
  $adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
}
if (-not $DeviceId) {
  $devices = & $adb devices | Select-String -Pattern '^(\S+)\s+device$' |
    ForEach-Object { $_.Matches[0].Groups[1].Value }
  if (-not $devices) { throw 'No Android device or emulator connected (adb devices).' }
  $DeviceId = @($devices)[0]
}
$model = (& $adb -s $DeviceId shell getprop ro.product.model).Trim()
$sdk = (& $adb -s $DeviceId shell getprop ro.build.version.sdk).Trim()
$label = "$model (API $sdk, $DeviceId)"
Write-Host "Device: $label"

# --- 3. Copy data to the device ---------------------------------------------
$rows = Import-Csv $csv -Encoding UTF8
Invoke-Native $adb @('-s', $DeviceId, 'shell', "rm -rf $remote; mkdir -p $remote")
Invoke-Native $adb @('-s', $DeviceId, 'push', $csv, "$remote/ground_truth.csv")
foreach ($row in $rows) {
  $image = Join-Path $DataDir $row.file
  if (-not (Test-Path $image)) { throw "Photo listed in the CSV is missing: $image" }
  Invoke-Native $adb @('-s', $DeviceId, 'push', $image, "$remote/$($row.file)")
}
# adb creates the folder as user 'shell' (rwxrws---), which the app cannot
# enter; open it up for this temporary run (it is deleted afterwards).
Invoke-Native $adb @('-s', $DeviceId, 'shell', "chmod 777 $remote && chmod 666 $remote/*")
Write-Host "Copied $($rows.Count) photos to $remote"

# --- 4. Run the evaluation on the device ------------------------------------
Push-Location $repo
try {
  Invoke-Native $Flutter @(
    'test', 'integration_test/ocr_eval_test.dart',
    '-d', $DeviceId, '--no-uninstall',
    "--dart-define=GROUND_TRUTH_SHA256=$hash",
    "--dart-define=EVAL_DEVICE=$label"
  )
} finally {
  Pop-Location
}

# --- 5. Collect the report (outside the repository) -------------------------
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$out = Join-Path $DataDir ("reports\{0}_{1}" -f $stamp, ($DeviceId -replace '[^\w.-]', '_'))
New-Item -ItemType Directory -Force $out | Out-Null
Invoke-Native $adb @('-s', $DeviceId, 'pull', "$remote/report.json", (Join-Path $out 'report.json'))
Invoke-Native $adb @('-s', $DeviceId, 'pull', "$remote/report.md", (Join-Path $out 'report.md'))
if (-not $KeepOnDevice) {
  Invoke-Native $adb @('-s', $DeviceId, 'shell', "rm -rf $remote")
}
Write-Host ''
Get-Content (Join-Path $out 'report.md') -Encoding UTF8 | Select-Object -First 8
Write-Host ''
Write-Host "Full report: $out" -ForegroundColor Green
