#!/usr/bin/env bash
# =============================================================================
# verificar-mac.sh — Mi Día: Diagnóstico del entorno macOS
# =============================================================================
# Uso:
#   chmod +x scripts/verificar-mac.sh
#   ./scripts/verificar-mac.sh
#
# Solo diagnóstico. No instala, no modifica, no realiza push.
# =============================================================================

set -uo pipefail

# ── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()     { echo -e "  ${GREEN}✔${RESET}  $*"; }
fail()   { echo -e "  ${RED}✖${RESET}  $*"; }
warn()   { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
info()   { echo -e "  ${BLUE}ℹ${RESET}  $*"; }
sep()    { echo -e "${CYAN}────────────────────────────────────────────${RESET}"; }
check()  { echo -e "${BOLD}▶ $*${RESET}"; }

ERRORES=0
reg_error() { ERRORES=$((ERRORES + 1)); }

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${BLUE}║   Mi Día — Diagnóstico del entorno Mac   ║${RESET}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# =============================================================================
# SISTEMA OPERATIVO
# =============================================================================
sep
check "Sistema operativo"
echo ""
if [[ "$(uname -s)" == "Darwin" ]]; then
  MAC_VER=$(sw_vers -productVersion)
  ok "macOS $MAC_VER"
else
  fail "No es macOS ($(uname -s)). Este script es exclusivo para Mac."
  reg_error
fi

# =============================================================================
# NODE.JS
# =============================================================================
sep
check "Node.js"
echo ""
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
  if [[ "$NODE_MAJOR" -ge 20 ]]; then
    ok "Node.js $NODE_VER (compatible)"
  else
    fail "Node.js $NODE_VER detectado — se requiere v20 o superior"
    info "Instala desde: https://nodejs.org o con nvm: nvm install --lts"
    reg_error
  fi
else
  fail "Node.js no encontrado"
  info "Instala desde: https://nodejs.org"
  reg_error
fi

# =============================================================================
# NPM
# =============================================================================
sep
check "npm"
echo ""
if command -v npm &>/dev/null; then
  ok "npm v$(npm --version)"
else
  fail "npm no encontrado (normalmente viene incluido con Node.js)"
  reg_error
fi

# =============================================================================
# GIT
# =============================================================================
sep
check "Git"
echo ""
if command -v git &>/dev/null; then
  ok "Git $(git --version | awk '{print $3}')"
else
  fail "Git no encontrado"
  info "Instala con: xcode-select --install"
  reg_error
fi

# =============================================================================
# XCODE
# =============================================================================
sep
check "Xcode y herramientas de compilación"
echo ""

if command -v xcodebuild &>/dev/null; then
  XCODE_VER=$(xcodebuild -version 2>/dev/null | head -1 || echo "desconocida")
  XCODE_BUILD=$(xcodebuild -version 2>/dev/null | tail -1 || echo "")
  ok "Xcode: $XCODE_VER $XCODE_BUILD"
else
  fail "xcodebuild no disponible — Xcode no está instalado o no está en el PATH"
  info "Instala Xcode desde la Mac App Store"
  reg_error
fi

if command -v xcode-select &>/dev/null; then
  XCODE_PATH=$(xcode-select -p 2>/dev/null || echo "no configurado")
  if [[ "$XCODE_PATH" == *"Xcode"* ]]; then
    ok "xcode-select: $XCODE_PATH"
  else
    warn "xcode-select apunta a: $XCODE_PATH (puede no ser Xcode completo)"
    info "Configura con: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
  fi
else
  fail "xcode-select no encontrado"
  reg_error
fi

# Licencia de Xcode
if command -v xcodebuild &>/dev/null; then
  if xcodebuild -license status &>/dev/null 2>&1; then
    ok "Licencia de Xcode: aceptada"
  else
    warn "Licencia de Xcode: pendiente de aceptar"
    info "Ejecuta: sudo xcodebuild -license accept"
  fi
fi

# iOS SDK
if command -v xcodebuild &>/dev/null; then
  IOS_SDK=$(xcodebuild -showsdks 2>/dev/null | grep -i "iphoneos" | tail -1 || echo "")
  if [[ -n "$IOS_SDK" ]]; then
    ok "iOS SDK: $IOS_SDK"
  else
    warn "No se detectó iOS SDK. Verifica la instalación de Xcode."
  fi
fi

# =============================================================================
# PROYECTO
# =============================================================================
sep
check "Proyecto Mi Día"
echo ""

if [[ -f "package.json" ]]; then
  APP_NAME=$(node -e "console.log(require('./package.json').name)" 2>/dev/null || echo "desconocido")
  APP_VER=$(node -e "console.log(require('./package.json').version)" 2>/dev/null || echo "desconocida")
  ok "package.json encontrado (app: $APP_NAME v$APP_VER)"
else
  fail "package.json no encontrado — ejecuta este script desde la raíz del proyecto"
  reg_error
fi

if [[ -f "package-lock.json" ]]; then
  ok "package-lock.json encontrado (usar npm ci para instalación reproducible)"
else
  warn "package-lock.json no encontrado (se usará npm install)"
fi

if [[ -f "capacitor.config.ts" ]] || [[ -f "capacitor.config.json" ]]; then
  if [[ -f "capacitor.config.ts" ]]; then
    WEB_DIR=$(grep -E 'webDir\s*:' capacitor.config.ts | grep -oE "'[^']+'" | tr -d "'" || echo "www")
  else
    WEB_DIR=$(node -e "const c=require('./capacitor.config.json'); console.log(c.webDir||'www')" 2>/dev/null || echo "www")
  fi
  ok "capacitor.config encontrado (webDir: $WEB_DIR)"
else
  fail "No se encontró capacitor.config.ts ni capacitor.config.json"
  reg_error
fi

# =============================================================================
# DEPENDENCIAS INSTALADAS
# =============================================================================
sep
check "Dependencias instaladas"
echo ""

if [[ -d "node_modules" ]]; then
  ok "node_modules existe"

  for pkg in "@capacitor/core" "@capacitor/ios" "@capacitor/cli" "@ionic/angular" "@angular/core"; do
    if [[ -d "node_modules/$pkg" ]]; then
      PKG_VER=$(node -e "console.log(require('./node_modules/$pkg/package.json').version)" 2>/dev/null || echo "?")
      ok "$pkg: v$PKG_VER"
    else
      fail "$pkg no instalado (ejecuta npm ci)"
      reg_error
    fi
  done
else
  fail "node_modules no existe — ejecuta: npm ci"
  reg_error
fi

# =============================================================================
# DIRECTORIO WEB (webDir)
# =============================================================================
sep
check "Directorio web compilado ($WEB_DIR)"
echo ""
WEB_DIR="${WEB_DIR:-www}"
if [[ -d "$WEB_DIR" ]] && [[ -f "$WEB_DIR/index.html" ]]; then
  ok "$WEB_DIR/index.html encontrado"
else
  warn "$WEB_DIR/index.html no encontrado — ejecuta: npm run build"
  info "Esto se hará automáticamente al ejecutar setup-mac.sh"
fi

# =============================================================================
# PLATAFORMA iOS
# =============================================================================
sep
check "Plataforma iOS (Capacitor)"
echo ""
if [[ -d "ios" ]]; then
  ok "Directorio ios/ existe"
  XC_WORKSPACE=$(find ios -name "*.xcworkspace" -maxdepth 3 2>/dev/null | head -1 || true)
  XC_PROJECT=$(find ios -name "*.xcodeproj" -maxdepth 3 2>/dev/null | head -1 || true)
  if [[ -n "$XC_WORKSPACE" ]]; then
    ok "Workspace Xcode: $XC_WORKSPACE"
  elif [[ -n "$XC_PROJECT" ]]; then
    ok "Proyecto Xcode: $XC_PROJECT"
  else
    warn "No se encontró .xcworkspace ni .xcodeproj en ios/"
  fi
else
  warn "Directorio ios/ no existe — se creará al ejecutar setup-mac.sh"
  info "Comando: npx cap add ios"
fi

# =============================================================================
# GIT / REPOSITORIO
# =============================================================================
sep
check "Estado del repositorio Git"
echo ""
if [[ -d ".git" ]]; then
  ok "Repositorio Git inicializado"
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "desconocida")
  ok "Rama actual: $BRANCH"
  REMOTE=$(git remote get-url origin 2>/dev/null || echo "no configurado")
  if [[ "$REMOTE" != "no configurado" ]]; then
    ok "Remoto origin: $REMOTE"
  else
    warn "No hay remoto 'origin' configurado"
    info "Añade el remoto con: git remote add origin <URL_DEL_REPO>"
  fi
  COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
  ok "Commits en el historial: $COMMITS"
else
  warn "No es un repositorio Git"
fi

# =============================================================================
# RESUMEN FINAL
# =============================================================================
sep
echo ""
if [[ "$ERRORES" -eq 0 ]]; then
  echo -e "${BOLD}${GREEN}✅  Todo listo. Puedes ejecutar:${RESET}"
  echo ""
  echo "    ./scripts/setup-mac.sh"
else
  echo -e "${BOLD}${RED}❌  Se encontraron $ERRORES problema(s) que deben resolverse.${RESET}"
  echo ""
  echo -e "    Revisa los errores marcados con ${RED}✖${RESET} antes de continuar."
fi
echo ""
