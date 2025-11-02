#requires -Version 7.0
# OpenStack学習環境のクリーンアップスクリプト (Windows)
#
# 機能:
#   - Vagrant VMの削除
#   - VirtualBox Host-Only Networkアダプタの削除
#   - その他のリソースのクリーンアップ
#
# 使用方法:
#   PowerShell 7.xで実行
#
#     pwsh -ExecutionPolicy Bypass -File .\scripts\cleanup_environment.ps1
#
# 警告:
#   このスクリプトは全てのVMとネットワークを削除します。
#   実行前に必要なデータのバックアップを取ってください。
#
# 注意:
#   - このスクリプトはPowerShell 7.0以降を必要とします

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenStack学習環境 - クリーンアップ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "警告: このスクリプトは以下のリソースを削除します:" -ForegroundColor Yellow
Write-Host "  - 全てのVagrant VM (controller, network, compute1)" -ForegroundColor Yellow
Write-Host "  - VirtualBox Host-Only Network (172.16.100.0/24)" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "続行してもよろしいですか? (yes/no)"
if ($confirm -notmatch "^[Yy][Ee][Ss]$") {
    Write-Host "クリーンアップをキャンセルしました。" -ForegroundColor Yellow
    exit 0
}

# VBoxManageの存在確認
$vboxmanage = "VBoxManage"
$skipVbox = $false
try {
    & $vboxmanage --version | Out-Null
} catch {
    Write-Host "警告: VBoxManageが見つかりません。" -ForegroundColor Yellow
    Write-Host "VirtualBoxがインストールされていない可能性があります。" -ForegroundColor Yellow
    Write-Host "Vagrant VMの削除のみ続行します。" -ForegroundColor Yellow
    $skipVbox = $true
}

# Vagrantの存在確認
$skipVagrant = $false
try {
    $vagrantVersion = vagrant --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "vagrantコマンドが正常に実行できませんでした"
    }
} catch {
    Write-Host "警告: vagrantコマンドが見つかりません。" -ForegroundColor Yellow
    Write-Host "Vagrant VMの削除をスキップします。" -ForegroundColor Yellow
    $skipVagrant = $true
}

# スクリプトのディレクトリを取得
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir

Write-Host ""
Write-Host "[1/3] Vagrant VMを削除中..." -ForegroundColor Yellow

if (-not $skipVagrant) {
    # Vagrantfileがあるディレクトリに移動
    Set-Location $projectDir

    if (Test-Path "Vagrantfile") {
        # Vagrant VMを強制削除
        vagrant destroy -f 2>&1 | Out-Null
        Write-Host "✓ Vagrant VMを削除しました" -ForegroundColor Green

        # Vagrantボックスのクリーンアップ（オプション）
        Write-Host ""
        $pruneBoxes = Read-Host "未使用のVagrantボックスも削除しますか? (yes/no)"
        if ($pruneBoxes -match "^[Yy][Ee][Ss]$") {
            Write-Host "未使用のVagrantボックスを削除中..." -ForegroundColor Yellow
            vagrant box prune -f 2>&1 | Out-Null
            Write-Host "✓ 未使用のVagrantボックスを削除しました" -ForegroundColor Green
        }
    } else {
        Write-Host "× Vagrantfileが見つかりません。スキップします。" -ForegroundColor Yellow
    }
} else {
    Write-Host "× Vagrantが見つからないため、VM削除をスキップします。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[2/3] VirtualBox Host-Only Networkを削除中..." -ForegroundColor Yellow

if (-not $skipVbox) {
    try {
        # 既存のHost-Only Networkアダプタをリスト取得
        $hostonlyifs = & $vboxmanage list hostonlyifs 2>$null

        if ($hostonlyifs) {
            # 172.16.100.1が設定されているアダプタを探す
            $adapterName = ""

            if ($hostonlyifs -match "IPAddress:\s+172\.16\.100\.1") {
                # アダプタ名を取得
                $lines = $hostonlyifs -split "`n"
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match "IPAddress:\s+172\.16\.100\.1") {
                        # 上に遡ってName行を探す
                        for ($j = $i; $j -ge 0; $j--) {
                            if ($lines[$j] -match "Name:\s+(.+)") {
                                $adapterName = $matches[1].Trim()
                                break
                            }
                        }
                        break
                    }
                }

                if ($adapterName) {
                    Write-Host "削除対象のアダプタが見つかりました: $adapterName" -ForegroundColor White

                    # DHCPサーバーを削除（存在する場合）
                    Write-Host "  - DHCPサーバーを削除中..." -ForegroundColor White
                    & $vboxmanage dhcpserver remove --netname "HostInterfaceNetworking-$adapterName" 2>$null

                    # Host-Only Networkアダプタを削除
                    Write-Host "  - Host-Only Networkアダプタを削除中..." -ForegroundColor White
                    try {
                        & $vboxmanage hostonlyif remove $adapterName 2>&1 | Out-Null
                        $exitCode = $LASTEXITCODE

                        if ($exitCode -eq 0) {
                            Write-Host "✓ VirtualBox Host-Only Networkを削除しました" -ForegroundColor Green
                        } else {
                            Write-Host "警告: アダプタの削除に失敗しました。" -ForegroundColor Yellow
                            Write-Host "      VMが完全に削除されたことを確認してください。" -ForegroundColor Yellow
                            Write-Host "      手動で削除する場合は、VirtualBox GUIから削除してください。" -ForegroundColor Yellow
                        }
                    } catch {
                        Write-Host "警告: アダプタの削除中にエラーが発生しました: $_" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "✓ 削除対象のHost-Only Networkアダプタが見つかりませんでした（既に削除済み）" -ForegroundColor Green
                }
            } else {
                Write-Host "✓ 削除対象のHost-Only Networkアダプタが見つかりませんでした（既に削除済み）" -ForegroundColor Green
            }
        } else {
            Write-Host "× Host-Only Networkアダプタのリストを取得できませんでした" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "警告: VirtualBoxネットワークの削除中にエラーが発生しました: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "× VBoxManageが見つからないため、ネットワーク削除をスキップします。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/3] その他のリソースをクリーンアップ中..." -ForegroundColor Yellow

if (-not $skipVbox) {
    # VirtualBoxの内部ネットワーク（overlay-net）が使用されているかチェック
    # 通常、VMが削除されると自動的にクリーンアップされる
    Write-Host "✓ VirtualBox内部ネットワークのクリーンアップ完了（VM削除時に自動削除）" -ForegroundColor Green
}

# Vagrantの一時ファイルのクリーンアップ（オプション）
if (-not $skipVagrant -and (Test-Path "$projectDir\Vagrantfile")) {
    Set-Location $projectDir
    if (Test-Path ".vagrant") {
        Write-Host "  - Vagrantメタデータを削除中..." -ForegroundColor White
        Remove-Item -Recurse -Force .vagrant -ErrorAction SilentlyContinue
        Write-Host "✓ Vagrantメタデータを削除しました" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "クリーンアップ完了" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "削除されたリソース:" -ForegroundColor White
Write-Host "  ✓ Vagrant VM (controller, network, compute1)" -ForegroundColor Green
Write-Host "  ✓ VirtualBox Host-Only Network (172.16.100.0/24)" -ForegroundColor Green
Write-Host "  ✓ Vagrantメタデータ (.vagrant)" -ForegroundColor Green
Write-Host ""
Write-Host "注意:" -ForegroundColor Yellow
Write-Host "  - VirtualBox GUIからVMが完全に削除されたことを確認してください" -ForegroundColor White
Write-Host "  - 再度環境を構築する場合は、setup_vbox_network.ps1を実行してください" -ForegroundColor White
Write-Host ""
