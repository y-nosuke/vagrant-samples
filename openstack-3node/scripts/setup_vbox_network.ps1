#requires -Version 7.0
# OpenStack学習環境用 VirtualBox Host-Only Network セットアップスクリプト (Windows)
#
# 機能:
#   - VirtualBox Host-Only Networkアダプタの作成
#   - 管理ネットワーク (172.16.100.0/24) の設定
#   - DHCPサーバーの無効化
#
# 使用方法:
#   PowerShell 7.xで管理者権限で実行
#
#     pwsh -ExecutionPolicy Bypass -File .\scripts\setup_vbox_network.ps1
#
# 注意:
#   - このスクリプトはPowerShell 7.0以降を必要とします
#   - 管理者権限が必要です

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenStack学習環境 - ネットワーク設定" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# VBoxManageの存在確認
$vboxmanage = "VBoxManage"
try {
    & $vboxmanage --version | Out-Null
} catch {
    Write-Host "エラー: VBoxManageが見つかりません。" -ForegroundColor Red
    Write-Host "VirtualBoxがインストールされているか確認してください。" -ForegroundColor Red
    exit 1
}

Write-Host "[1/4] 既存のHost-Only Networkアダプタを確認中..." -ForegroundColor Yellow

# 既存のHost-Only Networkアダプタをリスト取得
$hostonlyifs = & $vboxmanage list hostonlyifs

# 172.16.100.1のアダプタが既に存在するか確認
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
    Write-Host "✓ 管理ネットワーク用アダプタが既に存在します: $adapterName" -ForegroundColor Green
} else {
    Write-Host "× 管理ネットワーク用アダプタが見つかりません。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[2/4] Host-Only Networkアダプタを作成中..." -ForegroundColor Yellow

    try {
        # Host-Only Networkアダプタを作成
        $output = & $vboxmanage hostonlyif create 2>&1
        $exitCode = $LASTEXITCODE

        # 出力を文字列に変換（エラーストリームも含む）
        $outputString = ($output | ForEach-Object { $_.ToString() }) -join "`n"

        # 成功メッセージが含まれているか確認
        $isSuccess = $outputString -match "successfully created"

        if ($exitCode -ne 0 -and -not $isSuccess) {
            throw "アダプタの作成に失敗しました (終了コード: $exitCode): $outputString"
        }

        # 作成されたアダプタ名を取得
        if ($outputString -match "'(.+)'") {
            $adapterName = $matches[1]
            Write-Host "✓ アダプタを作成しました: $adapterName" -ForegroundColor Green
        } else {
            throw "アダプタ名の取得に失敗しました。出力: $outputString"
        }
    } catch {
        Write-Host "エラー: $_" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "[3/4] IPアドレスを設定中..." -ForegroundColor Yellow

    try {
        # IPアドレスとネットマスクを設定
        & $vboxmanage hostonlyif ipconfig $adapterName --ip 172.16.100.1 --netmask 255.255.255.0 2>&1 | Out-Null
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            throw "IPアドレスの設定に失敗しました (終了コード: $exitCode)"
        }
        Write-Host "✓ IPアドレスを設定しました: 172.16.100.1/24" -ForegroundColor Green
    } catch {
        Write-Host "エラー: $_" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "[4/4] DHCPサーバーを無効化中..." -ForegroundColor Yellow

    try {
        # DHCPサーバーを無効化（静的IP使用のため）
        & $vboxmanage dhcpserver remove --netname "HostInterfaceNetworking-$adapterName" 2>$null
        Write-Host "✓ DHCPサーバーを無効化しました" -ForegroundColor Green
    } catch {
        # DHCPサーバーが存在しない場合はエラーでも問題なし
        Write-Host "✓ DHCPサーバーは無効です（または存在しません）" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "設定完了" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "管理ネットワーク設定:" -ForegroundColor White
Write-Host "  ネットワーク: 172.16.100.0/24" -ForegroundColor White
Write-Host "  ゲートウェイ: 172.16.100.1 (ホストOS)" -ForegroundColor White
Write-Host "  アダプタ名: $adapterName" -ForegroundColor White
Write-Host ""
Write-Host "ノードIPアドレス:" -ForegroundColor White
Write-Host "  Controller: 172.16.100.10" -ForegroundColor White
Write-Host "  Network:    172.16.100.20" -ForegroundColor White
Write-Host "  Compute1:   172.16.100.31" -ForegroundColor White
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Yellow
Write-Host "  1. vagrant up を実行してVMを起動" -ForegroundColor White
Write-Host "  2. ssh vagrant@172.16.100.10 でControllerノードに接続可能" -ForegroundColor White
Write-Host ""
