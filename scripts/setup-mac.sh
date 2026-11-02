#!/usr/bin/env bash
# =============================================================================
# setup-mac.sh — Mi Día: Preparación completa del proyecto para iOS en macOS
# =============================================================================
# Uso:
#   chmod +x scripts/setup-mac.sh
#   ./scripts/setup-mac.sh
#
# Requisitos previos en el Mac:
#   - Xcode 15 o superior (instalado desde Mac App Store)
#   - Node.js 20 o superior
#   - npm 9 o superior
#
# Este script es idempotente: puede ejecutarse varias veces sin efectos dañinos.
# =============================================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()    { echo -e "${GREEN}✔${RESET}  $*"; }
info()  { echo -e "${BLUE}ℹ${RESET}  $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET}  $*"; }
error() { echo -e "${RED}✖${RESET}  $*" >&2; }
die()   { error "$*"; exit 1; }
sep()   { echo -e "${CYAN}────────────────────────────────────────────${RESET}"; }

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${BLUE}║     Mi Día — Configuración para iOS     ║${RESET}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${RESET}"
echo ""

# =============================================================================
# 1. VERIFICACIONES DEL ENTORNO
# =============================================================================
sep
echo -e "${BOLD}1. Verificando el entorno...${RESET}"
sep

# Sistema operativo
if [[ "$(uname -s)" != "Darwin" ]]; then
  die "Este script solo puede ejecutarse en macOS. Sistema detectado: $(uname -s)"
fi
ok "Sistema operativo: macOS $(sw_vers -productVersion)"

# Directorio raíz del proyecto
if [[ ! -f "package.json" ]]; then
  die "No se encontró package.json. Ejecuta este script desde la raíz del proyecto."
fi
ok "Directorio del proyecto: $(pwd)"

# Node.js
if ! command -v node &>/dev/null; then
  die "Node.js no está instalado. Instálalo desde https://nodejs.org (versión 20 LTS o superior)."
fi
NODE_VERSION=$(node --version)
NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
if [[ "$NODE_MAJOR" -lt 20 ]]; then
  die "Node.js $NODE_VERSION detectado. Se requiere v20 o superior."
fi
ok "Node.js: $NODE_VERSION"

# npm
if ! command -v npm &>/dev/null; then
  die "npm no está disponible. Reinstala Node.js desde https://nodejs.org"
fi
NPM_VERSION=$(npm --version)
ok "npm: v$NPM_VERSION"

# Xcode y xcodebuild
if ! command -v xcodebuild &>/dev/null; then
  die "xcodebuild no está disponible. Instala Xcode desde la Mac App Store y ábrelo al menos una vez para aceptar la licencia."
fi
XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 || echo "desconocida")
ok "Xcode: $XCODE_VERSION"

# xcode-select (herramientas de línea de comandos)
XCODE_SELECT_PATH=$(xcode-select -p 2>/dev/null || true)
if [[ -z "$XCODE_SELECT_PATH" ]]; then
  die "Las herramientas de desarrollo de Xcode no están seleccionadas. Ejecuta: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
fi
ok "xcode-select apunta a: $XCODE_SELECT_PATH"

# Aceptar licencia de Xcode si es necesario (no interactivo)
if ! xcodebuild -license status &>/dev/null 2>&1; then
  warn "La licencia de Xcode no ha sido aceptada. Ejecuta: sudo xcodebuild -license accept"
  warn "Continuando de todas formas..."
fi

# Git (no obligatorio pero útil)
if command -v git &>/dev/null; then
  ok "Git: $(git --version | awk '{print $3}')"
else
  warn "Git no está instalado. Puede instalarse con: xcode-select --install"
fi

echo ""

# =============================================================================
# 2. INSTALACIÓN DE DEPENDENCIAS
# =============================================================================
sep
echo -e "${BOLD}2. Instalando dependencias npm...${RESET}"
sep

# Preferir npm ci si existe package-lock.json (instalación reproducible)
if [[ -f "package-lock.json" ]]; then
  info "Usando npm ci (package-lock.json detectado)"
  npm ci --prefer-offline 2>&1 | tail -5 || die "npm ci falló. Prueba borrando node_modules y ejecutando npm install manualmente."
else
  warn "No se encontró package-lock.json. Usando npm install."
  npm install 2>&1 | tail -5 || die "npm install falló."
fi
ok "Dependencias instaladas correctamente"

echo ""

# =============================================================================
# 3. COMPILACIÓN WEB
# =============================================================================
sep
echo -e "${BOLD}3. Compilando la aplicación web...${RESET}"
sep

# Detectar comando de build del package.json
BUILD_SCRIPT=$(node -e "const p=require('./package.json'); console.log(p.scripts && p.scripts.build ? p.scripts.build : '')" 2>/dev/null)
if [[ -z "$BUILD_SCRIPT" ]]; then
  die "No se encontró el script 'build' en package.json"
fi
info "Comando de build: npm run build"

npm run build || die "La compilación web falló. Revisa los errores anteriores."

# Verificar directorio de salida (webDir de Capacitor)
WEB_DIR="www"
if [[ -f "capacitor.config.ts" ]]; then
  WEB_DIR=$(grep -E 'webDir\s*:' capacitor.config.ts | grep -oE "'[^']+'" | tr -d "'" || echo "www")
elif [[ -f "capacitor.config.json" ]]; then
  WEB_DIR=$(node -e "const c=require('./capacitor.config.json'); console.log(c.webDir || 'www')")
fi
info "webDir configurado: $WEB_DIR"

if [[ ! -d "$WEB_DIR" ]]; then
  die "El directorio '$WEB_DIR' no existe después de compilar. Revisa la configuración de Angular."
fi
if [[ ! -f "$WEB_DIR/index.html" ]]; then
  die "No se encontró index.html en '$WEB_DIR'. El build puede estar incompleto."
fi
ok "Compilación web exitosa → $WEB_DIR/index.html"

echo ""

# =============================================================================
# 4. CAPACITOR iOS
# =============================================================================
sep
echo -e "${BOLD}4. Configurando Capacitor iOS...${RESET}"
sep

# Verificar @capacitor/core
if [[ ! -d "node_modules/@capacitor/core" ]]; then
  die "@capacitor/core no está instalado. Verifica que npm ci se completó correctamente."
fi
CAP_CORE_VER=$(node -e "console.log(require('./node_modules/@capacitor/core/package.json').version)")
ok "@capacitor/core: v$CAP_CORE_VER"

# Verificar @capacitor/ios
if [[ ! -d "node_modules/@capacitor/ios" ]]; then
  die "@capacitor/ios no está instalado. Ejecuta: npm install @capacitor/ios"
fi
CAP_IOS_VER=$(node -e "console.log(require('./node_modules/@capacitor/ios/package.json').version)")
ok "@capacitor/ios: v$CAP_IOS_VER"

# Agregar plataforma iOS solo si no existe
if [[ ! -d "ios" ]]; then
  info "Plataforma iOS no encontrada. Ejecutando npx cap add ios..."
  npx cap add ios || die "cap add ios falló. Revisa que Xcode esté instalado correctamente."
  ok "Plataforma iOS creada en: ios/"
else
  ok "Plataforma iOS ya existe en: ios/ (omitiendo cap add ios)"
fi

# Sincronizar assets web con el proyecto iOS
info "Sincronizando assets web con iOS (npx cap sync ios)..."
npx cap sync ios || die "cap sync ios falló."
ok "Sincronización iOS completada"

echo ""

# =============================================================================
# 5. ABRIR EN XCODE
# =============================================================================
sep
echo -e "${BOLD}5. Abriendo proyecto en Xcode...${RESET}"
sep

# Verificar si existe workspace (CocoaPods) o proyecto directo
IOS_WORKSPACE=$(find ios -name "*.xcworkspace" -maxdepth 3 2>/dev/null | head -1 || true)
IOS_PROJECT=$(find ios -name "*.xcodeproj" -maxdepth 3 2>/dev/null | head -1 || true)

if [[ -n "$IOS_WORKSPACE" ]]; then
  info "Workspace detectado: $IOS_WORKSPACE"
  open "$IOS_WORKSPACE"
  ok "Xcode abierto con workspace"
elif [[ -n "$IOS_PROJECT" ]]; then
  info "Proyecto Xcode detectado: $IOS_PROJECT"
  npx cap open ios || open "$IOS_PROJECT"
  ok "Xcode abierto con proyecto"
else
  warn "No se encontró workspace ni proyecto. Intentando npx cap open ios..."
  npx cap open ios || warn "No se pudo abrir Xcode automáticamente. Abre manualmente: ios/App/App.xcodeproj"
fi

echo ""

# =============================================================================
# 6. RESUMEN FINAL
# =============================================================================
sep
echo -e "${BOLD}${GREEN}✅  Configuración completada exitosamente${RESET}"
sep
echo ""
echo -e "${BOLD}Versiones detectadas:${RESET}"
echo "  Node.js:          $NODE_VERSION"
echo "  npm:              v$NPM_VERSION"
echo "  Xcode:            $XCODE_VERSION"
echo "  @capacitor/core:  v$CAP_CORE_VER"
echo "  @capacitor/ios:   v$CAP_IOS_VER"
echo ""
echo -e "${BOLD}Resultado:${RESET}"
echo "  ✔  Dependencias instaladas"
echo "  ✔  Compilación web completada → $WEB_DIR/"
echo "  ✔  Plataforma iOS configurada → ios/"
echo "  ✔  Xcode abierto"
echo ""
echo -e "${BOLD}Próximos pasos en Xcode:${RESET}"
echo "  1. En la barra superior de Xcode, elige un simulador (ej: iPhone 16)"
echo "  2. Ve a: App → Signing & Capabilities"
echo "  3. En 'Team', selecciona tu Apple ID (añádelo en Xcode → Preferences → Accounts)"
echo "  4. Presiona  ▶  (Command + R) para compilar y ejecutar"
echo ""
echo -e "${BOLD}Para probar en un iPhone físico:${RESET}"
echo "  1. Conecta el iPhone con cable USB"
echo "  2. En iPhone: confía en el Mac cuando aparezca el mensaje"
echo "  3. Selecciona tu iPhone en la barra de dispositivos de Xcode"
echo "  4. En Signing & Capabilities, selecciona tu equipo (Apple ID gratuito funciona)"
echo "  5. Presiona  ▶  (Command + R)"
echo "  6. En iPhone: Ajustes → General → VPN y gestión del dispositivo"
echo "     → selecciona tu Apple ID → Confiar"
echo ""
echo -e "${BOLD}Para actualizar después de cambios desde Windows:${RESET}"
echo "  git pull"
echo "  npm ci"
echo "  npm run build"
echo "  npx cap sync ios"
echo "  npx cap open ios"
echo ""
