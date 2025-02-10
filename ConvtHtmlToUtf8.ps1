# スクリプトの引数設定
Param (
    [Parameter(Mandatory = $true)]
    [string]$InputPattern,   # 入力ファイルパターン (例: "*.html")
    [string]$OutputFolder = "output"  # 出力フォルダ (デフォルト: output)
)

function Convert-ToUtf8Html {
    param (
        [string]$InputFilePath,
        [string]$OutputFilePath
    )

    # 入力ファイルを読み込む
    $content = Get-Content -Path $InputFilePath -Raw

    # <META http-equiv="Content-Type" ...> を探す
    if ($content -match '<META http-equiv="Content-Type" content="text/html; charset=([^"]+)">') {
        $currentCharset = $matches[1]
        if ($currentCharset -ieq "UTF-8") {
            # UTF-8ならそのまま出力
            $newContent = $content
        } else {
            # UTF-8でない場合は置き換える
            $newContent = $content -replace '<META http-equiv="Content-Type" content="text/html; charset=[^"]+">', '<META http-equiv="Content-Type" content="text/html; charset=UTF-8">'
        }
    } elseif ($content -match '<HEAD>') {
        # <META http-equiv="Content-Type" ...> がない場合、<HEAD>の直後に追加
        $newContent = $content -replace '<HEAD>', '<HEAD>`n<META http-equiv="Content-Type" content="text/html; charset=UTF-8">'
    } else {
        Write-Host "Error: <HEAD> タグが見つかりません。ファイル: $InputFilePath" -ForegroundColor Red
        return
    }

    # UTF-8形式で出力
    $newContent | Set-Content -Path $OutputFilePath -Encoding UTF8
    Write-Host "Processed: $InputFilePath -> $OutputFilePath" -ForegroundColor Green
}

# 入力ファイルをワイルドカードパターンで取得
$inputFiles = Get-ChildItem -Path $InputPattern -File

if ($inputFiles.Count -eq 0) {
    Write-Host "Error: 入力ファイルが見つかりません: $InputPattern" -ForegroundColor Red
    exit 1
}

# 出力フォルダが存在しない場合は作成
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
}

# 各ファイルを処理
foreach ($inputFile in $inputFiles) {
    $outputFile = Join-Path -Path $OutputFolder -ChildPath $inputFile.Name
    Convert-ToUtf8Html -InputFilePath $inputFile.FullName -OutputFilePath $outputFile
}
