#requires -Version 7.0
# OpenStack学習環境の構築スクリプト (Windows)
#
# 機能:
#   - Host-Only Networkの作成
#   - ブリッジネットワークの確認
#   - Vagrant VMの起動（vagrant up）
#
# 使用方法:
#   PowerShell 7.xで実行
#
#     pwsh -ExecutionPolicy Bypass -File .\scripts\setup_environment.ps1
#
# 注意:
#   - このスクリプトはPowerShell 7.0以降を必要とします
#   - 管理者権限が必要です（ネットワーク作成のため）
#   - cleanup_environment.ps1の逆の操作を行います

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenStack学習環境 - 環境構築" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# スクリプトのディレクトリを取得
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$setupNetworkScript = Join-Path $scriptDir "setup_vbox_network.ps1"

# VBoxManageの存在確認
$vboxInstalled = $false
try {
    & VBoxManage --version | Out-Null
    $vboxInstalled = $true
} catch {
    Write-Host "エラー: VBoxManageが見つかりません。" -ForegroundColor Red
    Write-Host "VirtualBoxがインストールされているか確認してください。" -ForegroundColor Red
    Write-Host "確認スクリプトを実行: pwsh -ExecutionPolicy Bypass -File .\scripts\check_environment.ps1" -ForegroundColor Yellow
    exit 1
}

# Vagrantの存在確認
$vagrantInstalled = $false
try {
    vagrant --version | Out-Null
    $vagrantInstalled = $true
} catch {
    Write-Host "エラー: vagrantコマンドが見つかりません。" -ForegroundColor Red
    Write-Host "Vagrantがインストールされているか確認してください。" -ForegroundColor Red
    Write-Host "確認スクリプトを実行: pwsh -ExecutionPolicy Bypass -File .\scripts\check_environment.ps1" -ForegroundColor Yellow
    exit 1
}

# Vagrantfileの存在確認
if (-not (Test-Path (Join-Path $projectDir "Vagrantfile"))) {
    Write-Host "エラー: Vagrantfileが見つかりません。" -ForegroundColor Red
    Write-Host "プロジェクトディレクトリ ($projectDir) にVagrantfileが存在するか確認してください。" -ForegroundColor Red
    exit 1
}

# ========================================
# [1/3] Host-Only Networkの作成
# ========================================
Write-Host "[1/3] Host-Only Networkを設定中..." -ForegroundColor Yellow

if (Test-Path $setupNetworkScript) {
    try {
        & pwsh -ExecutionPolicy Bypass -File $setupNetworkScript
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Host-Only Networkの設定が完了しました" -ForegroundColor Green
        } else {
            Write-Host "× ネットワーク設定スクリプトの実行に失敗しました" -ForegroundColor Red
            Write-Host "  手動で setup_vbox_network.ps1 を実行してください" -ForegroundColor Yellow
            exit 1
        }
    } catch {
        Write-Host "× ネットワーク設定スクリプトの実行中にエラーが発生しました: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "× ネットワーク設定スクリプトが見つかりません: $setupNetworkScript" -ForegroundColor Red
    Write-Host "  手動で setup_vbox_network.ps1 を実行してください" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# ========================================
# [2/3] ブリッジネットワークの確認
# ========================================
Write-Host "[2/3] ブリッジネットワークを確認中..." -ForegroundColor Yellow

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
        Write-Host "    その後、このスクリプトを再実行してください" -ForegroundColor Gray
    } else {
        Write-Host "警告: 使用可能な物理ネットワークアダプタが見つかりませんでした" -ForegroundColor Yellow
        Write-Host "  ブリッジネットワークを使用する場合は、物理アダプタが必要です" -ForegroundColor Yellow
    }
} catch {
    Write-Host "警告: ブリッジネットワークの確認中にエラーが発生しました: $_" -ForegroundColor Yellow
    Write-Host "  ネットワークアダプタの確認に失敗しましたが、処理を続行します" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# [3/3] Vagrant VMの起動
# ========================================
Write-Host "[3/3] Vagrant VMを起動中..." -ForegroundColor Yellow

# プロジェクトディレクトリに移動
Set-Location $projectDir

Write-Host "  初回起動は20-30分かかります..." -ForegroundColor White
Write-Host "  ベースイメージのダウンロードとVM作成が行われます" -ForegroundColor White
Write-Host ""

# vagrant upを実行
try {
    vagrant up
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "✓ Vagrant VMの起動が完了しました" -ForegroundColor Green
    } else {
        Write-Host "× Vagrant VMの起動に失敗しました (終了コード: $exitCode)" -ForegroundColor Red
        Write-Host "  エラーメッセージを確認してください" -ForegroundColor Yellow
        exit $exitCode
    }
} catch {
    Write-Host "× Vagrant VMの起動中にエラーが発生しました: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "環境構築完了" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "作成されたリソース:" -ForegroundColor White
Write-Host "  ✓ VirtualBox Host-Only Network (172.16.100.0/24)" -ForegroundColor Green
Write-Host "  ✓ Vagrant VM (controller, network, compute1)" -ForegroundColor Green
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Yellow
Write-Host "  1. vagrant status でVM状態を確認" -ForegroundColor White
Write-Host "  2. vagrant ssh controller でControllerノードに接続" -ForegroundColor White
Write-Host "  3. docs/phase1_environment_setup.md を参照してネットワーク疎通確認" -ForegroundColor White
Write-Host ""
Write-Host "参考:" -ForegroundColor Yellow
Write-Host "  - ドキュメント: docs/phase1_environment_setup.md" -ForegroundColor White
Write-Host "  - Vagrantfile: Vagrantfile" -ForegroundColor White
Write-Host ""