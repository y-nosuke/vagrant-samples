#requires -Version 7.0
# OpenStack学習環境の前提条件確認スクリプト (Windows)
#
# 機能:
#   - 仮想化支援機能の確認（Intel VT-x / AMD-V）
#   - Hyper-Vの確認（VirtualBoxとの互換性）
#   - VirtualBoxのインストール確認
#   - Vagrantのインストール確認
#
# 使用方法:
#   PowerShell 7.xで実行
#
#     pwsh -ExecutionPolicy Bypass -File .\scripts\check_environment.ps1
#
# 注意:
#   - このスクリプトはPowerShell 7.0以降を必要とします
#   - 管理者権限は不要ですが、一部の情報は取得できない場合があります

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenStack学習環境 - 前提条件確認" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# チェック結果を記録
$allChecksPassed = $true

# ========================================
# [1/4] 仮想化支援機能の確認
# ========================================
Write-Host "[1/4] 仮想化支援機能を確認中..." -ForegroundColor Yellow

try {
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    $hypervisorPresent = $computerSystem.HypervisorPresent

    if ($hypervisorPresent) {
        Write-Host "✓ 仮想化支援機能が有効です" -ForegroundColor Green
    } else {
        Write-Host "× 仮想化支援機能が無効です" -ForegroundColor Red
        Write-Host "  警告: VirtualBoxでVMを実行するには、BIOS/UEFIで仮想化支援機能を有効にする必要があります" -ForegroundColor Yellow
        Write-Host "  推奨: PCを再起動し、BIOS/UEFI設定で「Virtualization Technology」を有効化してください" -ForegroundColor Yellow
        $allChecksPassed = $false
    }
} catch {
    Write-Host "警告: 仮想化支援機能の確認中にエラーが発生しました: $_" -ForegroundColor Yellow
    Write-Host "  システム情報の取得に失敗しましたが、処理を続行します" -ForegroundColor Yellow
}

# Hyper-Vの確認
try {
    $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
    if ($hyperV -and $hyperV.State -eq "Enabled") {
        Write-Host "警告: Hyper-Vが有効になっています" -ForegroundColor Yellow
        Write-Host "  Hyper-VとVirtualBoxは同時に使用できません" -ForegroundColor Yellow
        Write-Host "  Hyper-Vを無効化するには、以下を実行してください:" -ForegroundColor Yellow
        Write-Host "    bcdedit /set hypervisorlaunchtype off" -ForegroundColor White
        Write-Host "    その後、PCを再起動してください" -ForegroundColor Yellow
        $allChecksPassed = $false
    } else {
        Write-Host "✓ Hyper-Vは無効です（VirtualBoxと互換性あり）" -ForegroundColor Green
    }
} catch {
    # Hyper-Vの確認ができない場合（Windows 10 Homeなど）はスキップ
    Write-Host "  Hyper-Vの確認をスキップしました" -ForegroundColor Gray
}

Write-Host ""

# ========================================
# [2/4] VirtualBoxのインストール確認
# ========================================
Write-Host "[2/4] VirtualBoxのインストールを確認中..." -ForegroundColor Yellow

$vboxInstalled = $false
try {
    $vboxVersion = & VBoxManage --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ VirtualBoxがインストールされています: $vboxVersion" -ForegroundColor Green
        $vboxInstalled = $true
    } else {
        throw "VBoxManageコマンドが正常に実行できませんでした"
    }
} catch {
    Write-Host "× VirtualBoxがインストールされていません" -ForegroundColor Red
    Write-Host "  インストール方法:" -ForegroundColor Yellow
    Write-Host "    1. Chocolatey使用: choco install virtualbox -y" -ForegroundColor White
    Write-Host "    2. 公式サイトからダウンロード: https://www.virtualbox.org/wiki/Downloads" -ForegroundColor White
    $allChecksPassed = $false
}

Write-Host ""

# ========================================
# [3/4] Vagrantのインストール確認
# ========================================
Write-Host "[3/4] Vagrantのインストールを確認中..." -ForegroundColor Yellow

$vagrantInstalled = $false
try {
    $vagrantVersion = vagrant --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Vagrantがインストールされています: $vagrantVersion" -ForegroundColor Green
        $vagrantInstalled = $true
    } else {
        throw "vagrantコマンドが正常に実行できませんでした"
    }
} catch {
    Write-Host "× Vagrantがインストールされていません" -ForegroundColor Red
    Write-Host "  インストール方法:" -ForegroundColor Yellow
    Write-Host "    1. Chocolatey使用: choco install vagrant -y" -ForegroundColor White
    Write-Host "    2. 公式サイトからダウンロード: https://www.vagrantup.com/downloads" -ForegroundColor White
    $allChecksPassed = $false
}

Write-Host ""

# ========================================
# [4/4] ブリッジネットワークの確認
# ========================================
Write-Host "[4/4] ブリッジネットワークを確認中..." -ForegroundColor Yellow

try {
    # 物理アダプタで有効なものを取得
    $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {
        $_.PhysicalAdapter -eq $true -and $_.NetEnabled -eq $true
    }

    if ($networkAdapters) {
        Write-Host "✓ 使用可能な物理ネットワークアダプタ:" -ForegroundColor Green
        foreach ($adapter in $networkAdapters) {
            Write-Host "  - $($adapter.Name)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  注: Vagrantfileで自動検出を試みます" -ForegroundColor Gray
        Write-Host "  自動検出が失敗する場合は、環境変数で指定してください:" -ForegroundColor Gray
        Write-Host "    `$env:BRIDGE_INTERFACE=`"アダプタ名`"" -ForegroundColor White
    } else {
        Write-Host "警告: 使用可能な物理ネットワークアダプタが見つかりませんでした" -ForegroundColor Yellow
    }
} catch {
    Write-Host "警告: ブリッジネットワークの確認中にエラーが発生しました: $_" -ForegroundColor Yellow
    Write-Host "  ネットワークアダプタの確認に失敗しましたが、処理を続行します" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# 確認結果のサマリー
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
if ($allChecksPassed) {
    Write-Host "確認完了 - 全ての前提条件を満たしています" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "次のステップ:" -ForegroundColor Yellow
    Write-Host "  1. setup_environment.ps1 を実行して環境を構築" -ForegroundColor White
    Write-Host "  2. または、手動で setup_vbox_network.ps1 を実行後に vagrant up" -ForegroundColor White
} else {
    Write-Host "確認完了 - 未完了の項目があります" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "未完了の項目があります。上記のエラーメッセージを確認し、必要なインストールや設定を行ってください。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "必要な作業:" -ForegroundColor Yellow
    if (-not $vboxInstalled) {
        Write-Host "  - VirtualBoxのインストール" -ForegroundColor White
    }
    if (-not $vagrantInstalled) {
        Write-Host "  - Vagrantのインストール" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "全ての項目が完了したら、このスクリプトを再度実行して確認してください。" -ForegroundColor Yellow
}

Write-Host ""
