<#
.SYNOPSIS
    make가 설치되지 않은 Windows에서 Makefile 타깃을 실행하는 shim.

.DESCRIPTION
    Makefile과 이 스크립트는 모두 scripts/*.sh 한 곳을 호출한다.
    make가 설치되어 있으면 make에 그대로 위임하고, 없으면 Git Bash로 직접 실행한다.

.EXAMPLE
    ./make.ps1 doctor
    ./make.ps1 verify
    ./make.ps1 help
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target = 'help',

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

# --- make가 있으면 그대로 위임 ---------------------------------------------
$make = Get-Command make -ErrorAction SilentlyContinue
if ($make) {
    & $make.Source -C $RepoRoot $Target @Rest
    exit $LASTEXITCODE
}

# --- Git Bash 탐색 ----------------------------------------------------------
# 주의: PATH의 'bash' 는 보통 C:\Windows\System32\bash.exe, 즉 WSL이다.
# WSL에서 실행하면 경로(/mnt/d/...)와 도구(uv, pnpm, node)가 모두 달라
# 조용히 잘못된 결과가 나온다. Git Bash를 먼저 찾고 System32는 거부한다.
function Find-Bash {
    $candidates = @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }

    # git.exe 위치에서 형제 bash.exe를 찾는다.
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        $sibling = Join-Path (Split-Path (Split-Path $git.Source -Parent) -Parent) 'bin\bash.exe'
        if (Test-Path $sibling) { return $sibling }
    }

    # 마지막 수단: PATH의 bash. 단 WSL 런처는 제외한다.
    $cmd = Get-Command bash -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -notmatch '\\(System32|SysWOW64)\\') {
        return $cmd.Source
    }
    return $null
}

$bash = Find-Bash
if (-not $bash) {
    Write-Host "Git Bash를 찾을 수 없다." -ForegroundColor Red
    Write-Host ""
    Write-Host "이 저장소의 스크립트는 Git Bash로 실행된다 (WSL의 bash가 아니다)."
    Write-Host "둘 중 하나를 설치하라:"
    Write-Host "  winget install Git.Git      # Git Bash (권장)"
    Write-Host "  choco install make          # make 자체를 설치해도 된다"
    exit 1
}

# --- 타깃 → 스크립트 매핑 ---------------------------------------------------
$scriptTargets = @{
    'doctor'           = 'bash scripts/doctor.sh'
    'init'             = 'bash scripts/init.sh'
    'smoke'            = 'bash scripts/smoke.sh'
    'verify'           = 'bash scripts/verify.sh'
    'check-no-secrets' = 'bash scripts/check-no-secrets.sh'
}

# make 없이도 자주 쓰는 타깃은 직접 명령으로 실행한다.
$inlineTargets = @{
    'lint'          = 'uv run --directory apps/api ruff check . && pnpm --filter web lint'
    'typecheck'     = 'uv run --directory apps/api mypy src && pnpm --filter web typecheck'
    'test-unit'     = 'uv run --directory apps/api pytest tests -m unit -q'
    'test-contract' = 'uv run --directory apps/api pytest tests -m contract -q'
    'test-web'      = 'pnpm --filter web test'
    'test'          = 'uv run --directory apps/api pytest tests -m "unit or contract" -q && pnpm --filter web test'
    'clean'         = 'rm -rf apps/web/dist apps/web/node_modules/.vite; find . -type d \( -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache \) -not -path "./node_modules/*" -prune -exec rm -rf {} + 2>/dev/null; echo "정리 완료"'
}

$skipTargets = @{
    'test-db'          = 'DB 계층이 아직 없다 (TASK-0002)'
    'test-security'    = '두 사용자 fixture 미구현 (TASK-0002)'
    'test-e2e-smoke'   = 'Playwright 및 대상 화면 미구현 (TASK-0006)'
    'check-migrations' = 'Alembic 마이그레이션이 아직 없다 (TASK-0002)'
    'eval-offline'     = '평가 데이터셋이 아직 없다 (TASK-0012)'
    'seed-demo'        = 'DB와 fixture가 아직 없다 (TASK-0002)'
    'api-client'       = '생성할 API 스키마가 아직 없다 (TASK-0002)'
}

# bash 명령을 실행한다.
# 주의: 이 함수는 값을 반환하지 않는다. PowerShell 함수의 반환값은 출력 스트림
# 전체이므로, 반환값을 쓰면 bash의 출력이 호출부에 삼켜져 화면에 보이지 않는다.
# 종료 코드는 스크립트 범위 변수에 담는다.
$script:BashExitCode = 0
function Invoke-Bash([string]$Command) {
    # -l(로그인 셸)은 프로필을 읽으며 홈 디렉터리로 이동할 수 있다.
    # -c 를 쓰고 저장소 루트로 직접 이동해 실행 위치를 고정한다.
    $unixRoot = ($RepoRoot -replace '\\', '/')
    & $bash -c "cd '$unixRoot' && $Command"
    $script:BashExitCode = $LASTEXITCODE
}

switch ($Target) {
    'help' {
        Write-Host "매물온 — ./make.ps1 <타깃>" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  doctor             필요한 도구 점검과 설치 안내"
        Write-Host "  init               Python 런타임·의존성·.env 준비"
        Write-Host "  smoke              빠른 생존 확인"
        Write-Host "  verify             로컬 품질 게이트 (완료 전 필수)"
        Write-Host "  dev                web + api 개발 서버"
        Write-Host "  lint / typecheck   정적 검사"
        Write-Host "  test               실행 가능한 전체 테스트"
        Write-Host "  clean              빌드·캐시 정리"
        Write-Host ""
        Write-Host "미구현 타깃: $(($skipTargets.Keys | Sort-Object) -join ', ')" -ForegroundColor DarkGray
        Write-Host "make가 설치되어 있으면 'make <타깃>'도 동일하게 동작한다." -ForegroundColor DarkGray
        exit 0
    }

    'dev' {
        Write-Host "api: http://127.0.0.1:8000  |  web: http://127.0.0.1:5173"
        Write-Host "두 서버를 별도 창에서 실행한다. 종료하려면 각 창에서 Ctrl+C."
        Push-Location $RepoRoot
        try {
            Start-Process powershell -ArgumentList '-NoExit', '-Command',
                'uv run --directory apps/api uvicorn maemul_on.main:app --reload --app-dir src'
            Start-Process powershell -ArgumentList '-NoExit', '-Command', 'pnpm --filter web dev'
        }
        finally { Pop-Location }
        exit 0
    }

    default {
        if ($scriptTargets.ContainsKey($Target)) {
            Invoke-Bash $scriptTargets[$Target]
            exit $script:BashExitCode
        }
        if ($inlineTargets.ContainsKey($Target)) {
            Invoke-Bash $inlineTargets[$Target]
            exit $script:BashExitCode
        }
        if ($skipTargets.ContainsKey($Target)) {
            Write-Host "SKIPPED: $Target — $($skipTargets[$Target])" -ForegroundColor Yellow
            exit 0
        }

        Write-Host "알 수 없는 타깃: $Target" -ForegroundColor Red
        Write-Host "사용 가능한 타깃은 './make.ps1 help' 로 확인하라."
        exit 1
    }
}
