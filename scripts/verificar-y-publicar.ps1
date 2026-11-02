# =============================================================================
# verificar-y-publicar.ps1 — Mi Día: Verificación y publicación desde Windows
# =============================================================================
# Uso:
#   Abrir PowerShell en la raiz del proyecto y ejecutar:
#   .\scripts\verificar-y-publicar.ps1
#
# Requisitos previos:
#   - Git instalado y configurado (git config --global user.name/email)
#   - Remoto 'origin' configurado con GitHub
#   - Autenticacion de GitHub configurada (HTTPS con credential manager o SSH)
#
# Este script NO realiza force push, NO cambia de rama, NO sube archivos
# sensibles, NO almacena credenciales. Detiene la ejecucion si falla
# cualquier etapa critica.
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Colores y helpers ─────────────────────────────────────────────────────────
function Write-Ok    { param($msg) Write-Host "  [OK]  $msg" -ForegroundColor Green }
function Write-Fail  { param($msg) Write-Host "  [ERROR] $msg" -ForegroundColor Red }
function Write-Info  { param($msg) Write-Host "  [INFO] $msg" -ForegroundColor Cyan }
function Write-Warn  { param($msg) Write-Host "  [AVISO] $msg" -ForegroundColor Yellow }
function Write-Sep   { Write-Host "────────────────────────────────────────────" -ForegroundColor DarkCyan }
function Write-Step  { param($msg) Write-Host "`n$msg" -ForegroundColor White }

function Exit-Error {
    param($msg)
    Write-Fail $msg
    Write-Host "`n[CANCELADO] El proceso se detuvo debido a un error critico." -ForegroundColor Red
    exit 1
}

# ── Banner ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  Mi Dia — Verificar y Publicar (Windows)  " -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# =============================================================================
# 1. VERIFICACIONES DEL ENTORNO
# =============================================================================
Write-Sep
Write-Step "1. Verificando el entorno..."
Write-Sep

# Directorio raiz del proyecto
if (-not (Test-Path "package.json")) {
    Exit-Error "No se encontro package.json. Ejecuta este script desde la raiz del proyecto."
}
Write-Ok "Directorio del proyecto: $(Get-Location)"

# Node.js
try {
    $nodeVersion = (node --version 2>&1).Trim()
    $nodeMajor = [int]($nodeVersion -replace 'v', '' -split '\.')[0]
    if ($nodeMajor -lt 18) {
        Exit-Error "Node.js $nodeVersion detectado. Se requiere v18 o superior."
    }
    Write-Ok "Node.js: $nodeVersion"
} catch {
    Exit-Error "Node.js no esta instalado o no esta en el PATH. Descarga desde https://nodejs.org"
}

# npm
try {
    $npmVersion = (npm --version 2>&1).Trim()
    Write-Ok "npm: v$npmVersion"
} catch {
    Exit-Error "npm no disponible. Reinstala Node.js."
}

# Git
try {
    $gitVersion = (git --version 2>&1).Trim()
    Write-Ok "Git: $gitVersion"
} catch {
    Exit-Error "Git no esta instalado. Descarga desde https://git-scm.com"
}

# Repositorio Git
if (-not (Test-Path ".git")) {
    Exit-Error "Esta carpeta no es un repositorio Git. Ejecuta 'git init' primero."
}
Write-Ok "Repositorio Git: inicializado"

# Remoto origin
$remoteUrl = ""
try {
    $remoteUrl = (git remote get-url origin 2>&1).Trim()
    if ($remoteUrl -match "^fatal") {
        Exit-Error "No hay un remoto 'origin' configurado.`n  Ejecuta: git remote add origin https://github.com/Linzdhx/MiDia_app_mobile.git"
    }
    Write-Ok "Remoto origin: $remoteUrl"
} catch {
    Exit-Error "No hay un remoto 'origin' configurado.`n  Ejecuta: git remote add origin https://github.com/Linzdhx/MiDia_app_mobile.git"
}

# Rama actual
$currentBranch = (git rev-parse --abbrev-ref HEAD 2>&1).Trim()
Write-Ok "Rama actual: $currentBranch"

# Cambios pendientes (informativo)
$pendingChanges = (git status --short 2>&1)
if ($pendingChanges) {
    Write-Info "Cambios pendientes en el repositorio:"
    $pendingChanges | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    Write-Info "No hay cambios pendientes en el repositorio"
}

Write-Host ""

# =============================================================================
# 2. INSTALACION DE DEPENDENCIAS
# =============================================================================
Write-Sep
Write-Step "2. Instalando dependencias npm..."
Write-Sep

if (Test-Path "package-lock.json") {
    Write-Info "package-lock.json detectado. Usando 'npm ci' para instalacion reproducible."
    npm ci --prefer-offline
    if ($LASTEXITCODE -ne 0) {
        Exit-Error "npm ci fallo. Prueba eliminando node_modules y ejecutando npm install manualmente."
    }
} else {
    Write-Warn "package-lock.json no encontrado. Usando 'npm install'."
    npm install
    if ($LASTEXITCODE -ne 0) {
        Exit-Error "npm install fallo."
    }
}
Write-Ok "Dependencias instaladas correctamente"
Write-Host ""

# =============================================================================
# 3. PRUEBAS AUTOMATIZADAS
# =============================================================================
Write-Sep
Write-Step "3. Verificando y ejecutando pruebas..."
Write-Sep

# Leer el script de tests del package.json
$pkgJson = Get-Content "package.json" -Raw | ConvertFrom-Json
$testScript = $null
if ($pkgJson.scripts.PSObject.Properties.Name -contains "test") {
    $testScript = $pkgJson.scripts.test
}

if (-not $testScript) {
    Write-Warn "No se encontro script 'test' en package.json. Se omiten las pruebas."
} elseif ($testScript -match "ng test") {
    # Angular CLI / Karma: requiere navegador — no ejecutable en CI sin browser
    Write-Warn "El runner detectado es Angular CLI ('ng test')."
    Write-Warn "En este proyecto se usa vitest como runner de pruebas."
    Write-Info "Para ejecutar pruebas manualmente, abre otra terminal y ejecuta:"
    Write-Host "    npx vitest run" -ForegroundColor Yellow
    Write-Info "Omitiendo ejecucion automatica de pruebas en este flujo."
} elseif ($testScript -match "vitest") {
    Write-Info "Runner detectado: vitest. Ejecutando en modo --run (no interactivo)..."
    npx vitest run
    if ($LASTEXITCODE -ne 0) {
        Exit-Error "Las pruebas fallaron. Corrige los errores antes de continuar."
    }
    Write-Ok "Pruebas completadas exitosamente"
} else {
    Write-Info "Script de tests detectado: $testScript"
    Write-Warn "Runner desconocido. Omitiendo ejecucion automatica de pruebas."
    Write-Info "Ejecuta manualmente: npm test"
}

Write-Host ""

# =============================================================================
# 4. COMPILACION WEB
# =============================================================================
Write-Sep
Write-Step "4. Compilando la aplicacion..."
Write-Sep

# Verificar comando de build
if (-not ($pkgJson.scripts.PSObject.Properties.Name -contains "build")) {
    Exit-Error "No se encontro el script 'build' en package.json."
}

Write-Info "Ejecutando: npm run build"
npm run build
if ($LASTEXITCODE -ne 0) {
    Exit-Error "La compilacion fallo. Revisa los errores anteriores."
}

# Verificar que el directorio de salida existe
$webDir = "www"
try {
    # Intentar leer webDir de capacitor.config.ts
    $capConfig = Get-Content "capacitor.config.ts" -Raw -ErrorAction SilentlyContinue
    if ($capConfig -match "webDir\s*:\s*'([^']+)'") {
        $webDir = $matches[1]
    }
} catch { }

if (-not (Test-Path "$webDir\index.html")) {
    Exit-Error "No se encontro '$webDir\index.html' despues de compilar. El build puede estar incompleto."
}
Write-Ok "Compilacion exitosa. Salida en: $webDir\"
Write-Host ""

# =============================================================================
# 5. VERIFICACION DE SEGURIDAD (archivos sensibles)
# =============================================================================
Write-Sep
Write-Step "5. Verificando archivos antes del commit..."
Write-Sep

# Lista de patrones sensibles a bloquear
$patronesSensibles = @(
    '\.env$', '\.env\..*', '\.keystore$', '\.jks$', '\.p12$', '\.pfx$',
    '\.cer$', '\.pem$', '\.key$', 'google-services\.json$',
    'GoogleService-Info\.plist$', '\.mobileprovision$', 'AuthKey_.*\.p8$',
    'node_modules/', 'DerivedData/', '\.DS_Store$'
)

# Obtener archivos que Git va a incluir en el commit
$archivosAStagear = (git status --short --porcelain 2>&1) | Where-Object { $_ -match '^\?' -or $_ -match '^[MADRC]' }
$archivosConflicto = @()

foreach ($linea in $archivosAStagear) {
    $archivo = ($linea -replace '^.{3}', '').Trim()
    foreach ($patron in $patronesSensibles) {
        if ($archivo -match $patron) {
            $archivosConflicto += $archivo
        }
    }
}

if ($archivosConflicto.Count -gt 0) {
    Write-Fail "Se detectaron archivos potencialmente sensibles que NO deben subirse:"
    $archivosConflicto | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    Exit-Error "Agrega estos archivos a .gitignore antes de continuar."
}
Write-Ok "Sin archivos sensibles detectados"

Write-Host ""

# =============================================================================
# 6. COMMIT Y PUSH
# =============================================================================
Write-Sep
Write-Step "6. Preparando commit y push..."
Write-Sep

# Verificar si hay cambios para commitear
$statusOutput = (git status --short 2>&1)
if (-not $statusOutput) {
    Write-Ok "No hay cambios nuevos. El repositorio esta al dia."
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Proceso completado sin cambios nuevos.   " -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    exit 0
}

# Mostrar archivos que seran incluidos
Write-Info "Archivos que seran incluidos en el commit:"
git status --short | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
Write-Host ""

# Solicitar mensaje de commit
$commitMsg = ""
do {
    $commitMsg = Read-Host "  Escribe el mensaje del commit (o 'cancelar' para salir)"
    if ($commitMsg -eq "cancelar" -or $commitMsg -eq "") {
        if ($commitMsg -eq "cancelar") {
            Write-Warn "Proceso cancelado por el usuario."
            exit 0
        }
        Write-Warn "El mensaje del commit no puede estar vacio."
    }
} while ($commitMsg -eq "")

Write-Host ""

# Agregar solo archivos rastreados y nuevos (respetando .gitignore)
git add --all
if ($LASTEXITCODE -ne 0) {
    Exit-Error "git add fallo."
}

# Confirmar archivos a commitear
Write-Info "Archivos listos para el commit:"
git diff --cached --name-only | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
Write-Host ""

# Crear commit
git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) {
    Exit-Error "git commit fallo."
}
Write-Ok "Commit creado: '$commitMsg'"

# Push a la rama actual
Write-Info "Subiendo cambios a origin/$currentBranch..."
git push origin $currentBranch
if ($LASTEXITCODE -ne 0) {
    Write-Fail "git push fallo."
    Write-Info "Posibles causas:"
    Write-Host "    - No tienes permisos en el repositorio remoto" -ForegroundColor Yellow
    Write-Host "    - La autenticacion de GitHub no esta configurada" -ForegroundColor Yellow
    Write-Host "    - El repositorio remoto tiene cambios que no tienes localmente" -ForegroundColor Yellow
    Write-Info "Soluciones:"
    Write-Host "    - Configura GitHub CLI: gh auth login" -ForegroundColor Cyan
    Write-Host "    - O usa SSH: ssh-keygen y agrega la clave publica en GitHub" -ForegroundColor Cyan
    Write-Host "    - Si hay cambios remotos: git pull --rebase && vuelve a ejecutar" -ForegroundColor Cyan
    Exit-Error "Push fallido. Los cambios estan commiteados localmente."
}
Write-Ok "Push exitoso a origin/$currentBranch"

# =============================================================================
# RESUMEN FINAL
# =============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "         PROCESO COMPLETADO                " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Compilacion web:  OK ($webDir\)" -ForegroundColor Green
Write-Host "  Rama:             $currentBranch" -ForegroundColor Green
Write-Host "  Commit:           $commitMsg" -ForegroundColor Green
Write-Host "  Remoto:           $remoteUrl" -ForegroundColor Green
Write-Host ""
Write-Info "Verifica los cambios en GitHub:"
Write-Host "  $remoteUrl" -ForegroundColor Cyan
Write-Host ""
