# Mi Día — Guía de desarrollo: Windows, GitHub y macOS/iOS

Esta guía explica el flujo completo de trabajo: desarrollar en Windows, publicar en GitHub y compilar para iPhone en un Mac.

---

## Índice

1. [Preparación en Windows](#1-preparación-en-windows)
2. [Conectar el repositorio de GitHub](#2-conectar-el-repositorio-de-github)
3. [Preparación en macOS](#3-preparación-en-macos)
4. [Ejecutar en simulador iOS](#4-ejecutar-en-simulador-ios)
5. [Ejecutar en iPhone físico](#5-ejecutar-en-iphone-físico)
6. [Flujo de actualización continua](#6-flujo-de-actualización-continua)
7. [Solución de problemas comunes](#7-solución-de-problemas-comunes)

---

## 1. Preparación en Windows

### Requisitos

- Node.js v18 o superior → https://nodejs.org
- Git → https://git-scm.com
- PowerShell 5.1 o superior (viene incluido en Windows 10/11)
- Un editor de código (Visual Studio Code recomendado)

### Instalar dependencias del proyecto

Abre PowerShell en la carpeta raíz del proyecto (`d:\trabajo\MiDIa\midia`) y ejecuta:

```powershell
npm ci
```

> Si no existe `package-lock.json`, usa `npm install` en su lugar.

### Compilar el proyecto

```powershell
npm run build
```

Los archivos generados quedan en la carpeta `www/`. Este directorio es copiado automáticamente por Capacitor al proyecto iOS o Android en el paso de sincronización.

### Ejecutar en modo desarrollo (navegador web)

```powershell
npm start
# La app se abre en http://localhost:8100
```

### Ejecutar pruebas

El proyecto usa **vitest** como runner de pruebas:

```powershell
npx vitest run
```

> **Nota:** El comando `npm test` llama a `ng test`, que está configurado para Angular con Karma y requiere un navegador. Para pruebas no interactivas usa directamente `npx vitest run`.

### Usar el script de verificación y publicación

El script `scripts/verificar-y-publicar.ps1` automatiza verificaciones, compilación, commit y push.

**Primera vez: habilitar ejecución de scripts en PowerShell**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Ejecutar el script:**

```powershell
cd d:\trabajo\MiDIa\midia
.\scripts\verificar-y-publicar.ps1
```

El script realiza en orden:

1. Verifica Node.js, npm, Git y el remoto de GitHub
2. Instala dependencias con `npm ci`
3. Informa sobre las pruebas (vitest) y cómo ejecutarlas
4. Ejecuta `npm run build`
5. Revisa que no existan archivos sensibles (claves, certificados, `.env`)
6. Muestra los archivos que serán subidos
7. Solicita un mensaje de commit
8. Hace commit y push a la rama actual

> Si falla cualquier etapa, se detiene sin hacer push.

---

## 2. Conectar el repositorio de GitHub

El repositorio de este proyecto es:

```
https://github.com/Linzdhx/MiDia_app_mobile.git
```

### Si el proyecto no tiene repositorio Git todavía

```powershell
cd d:\trabajo\MiDIa\midia
git init
git add --all
git commit -m "Primer commit: Mi Día app"
git remote add origin https://github.com/Linzdhx/MiDia_app_mobile.git
git branch -M main
git push -u origin main
```

### Si el repositorio ya está inicializado (solo agregar el remoto)

```powershell
git remote add origin https://github.com/Linzdhx/MiDia_app_mobile.git
git push -u origin main
```

### Configurar autenticación en GitHub

**Opción A — GitHub CLI (recomendado):**

```powershell
winget install GitHub.cli
gh auth login
# Sigue las instrucciones en pantalla
```

**Opción B — Git Credential Manager (ya incluido con Git para Windows):**

Al hacer el primer `git push`, Git abrirá una ventana para autenticarte con GitHub en el navegador.

### Verificar que los archivos subieron

Abre en el navegador:
```
https://github.com/Linzdhx/MiDia_app_mobile
```

Deberías ver todos los archivos del proyecto excepto `node_modules/` y `www/` (excluidos por `.gitignore`).

---

## 3. Preparación en macOS

### Requisitos en el Mac

| Herramienta | Versión mínima | Cómo instalar |
|---|---|---|
| macOS | 13 Ventura | Actualización del sistema |
| Xcode | 15 | Mac App Store |
| Node.js | 20 LTS | https://nodejs.org |
| Git | incluido con Xcode | `xcode-select --install` |

### Paso 1 — Verificar el entorno

Antes de instalar nada, ejecuta el diagnóstico:

```bash
# Clonar el repositorio (solo primera vez)
git clone https://github.com/Linzdhx/MiDia_app_mobile.git
cd MiDia_app_mobile

# Dar permisos de ejecución a los scripts
chmod +x scripts/verificar-mac.sh
chmod +x scripts/setup-mac.sh

# Ejecutar diagnóstico
./scripts/verificar-mac.sh
```

El script lista el estado de cada dependencia y muestra errores a resolver antes de continuar.

### Paso 2 — Instalar Node.js si falta

Descarga el instalador `.pkg` desde https://nodejs.org (versión LTS recomendada).

Alternativamente, con nvm:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc   # o ~/.bash_profile
nvm install --lts
nvm use --lts
```

Verifica:

```bash
node --version   # debe mostrar v20 o superior
npm --version
```

### Paso 3 — Instalar Xcode

1. Abre la **Mac App Store**
2. Busca **Xcode** y descárgalo (puede tardar varios gigabytes)
3. Ábrelo al menos una vez para aceptar la licencia
4. En Terminal: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
5. Acepta la licencia: `sudo xcodebuild -license accept`

Verifica:

```bash
xcodebuild -version
# Debe mostrar: Xcode 15.x o superior
```

### Paso 4 — Configurar el proyecto con setup-mac.sh

```bash
cd MiDia_app_mobile   # o la carpeta donde clonaste el repo
./scripts/setup-mac.sh
```

Este script hace todo automáticamente:

| Paso | Acción |
|---|---|
| Verifica entorno | Node, npm, Xcode, xcode-select |
| Instala dependencias | `npm ci` |
| Compila la app | `npm run build` |
| Agrega iOS | `npx cap add ios` (solo si no existe) |
| Sincroniza | `npx cap sync ios` |
| Abre Xcode | `npx cap open ios` |

Al finalizar muestra un resumen con instrucciones para el siguiente paso en Xcode.

---

## 4. Ejecutar en simulador iOS

Después de que `setup-mac.sh` abra Xcode:

### En Xcode

1. Espera a que termine la indexación (barra de progreso en la parte superior)
2. En la barra de dispositivos (parte superior centro), haz clic en el selector de destino
3. Elige un simulador, por ejemplo: **iPhone 16** o **iPhone 16 Pro**
4. Presiona **▶ (Command + R)** o el botón de Run
5. El simulador se abrirá y la app se instalará automáticamente

> La primera compilación puede tardar varios minutos. Las siguientes son más rápidas.

### Configurar Signing & Capabilities

Si aparece un error de firma:

1. En el panel izquierdo de Xcode, selecciona el proyecto **App**
2. Selecciona el target **App**
3. Ve a la pestaña **Signing & Capabilities**
4. En **Team**, haz clic en el menú desplegable
5. Selecciona **Add an Account...** e inicia sesión con tu Apple ID (gratuito funciona para simulador)
6. Elige tu nombre como Team

---

## 5. Ejecutar en iPhone físico

### Requisitos

- iPhone con iOS 16 o superior
- Cable USB-A a Lightning o USB-C (según el modelo de iPhone)
- Apple ID (cuenta gratuita es suficiente para desarrollo personal)

### Pasos

**1. Conectar el iPhone al Mac**

Conecta el iPhone con el cable USB. Aparecerá un mensaje en el iPhone:
- Toca **Confiar** cuando pregunte si confías en este ordenador
- Ingresa el código de acceso del iPhone

**2. Seleccionar el iPhone en Xcode**

En la barra de dispositivos de Xcode (parte superior), el iPhone debería aparecer. Selecciónalo.

> Si aparece como "Sin autorización": en el iPhone ve a `Ajustes → General → VPN y gestión del dispositivo` y confía en el Mac.

**3. Configurar la firma para dispositivo físico**

1. En Xcode, selecciona el proyecto **App** en el panel izquierdo
2. Pestaña **Signing & Capabilities**
3. Marca **Automatically manage signing**
4. En **Team**, selecciona tu Apple ID

> Con un Apple ID gratuito puedes instalar la app en tu propio iPhone. La app expira en 7 días y hay que volver a instalarla.

**4. Compilar y ejecutar**

Presiona **▶ (Command + R)**.

Xcode compilará, instalará la app en el iPhone y la lanzará automáticamente.

**5. Confiar en el desarrollador en el iPhone**

La primera vez aparecerá un error "No es de confianza". En el iPhone:

1. Ve a `Ajustes → General → VPN y gestión del dispositivo`
2. Busca tu Apple ID bajo "App para desarrolladores"
3. Toca **Confiar en [tu Apple ID]**
4. Vuelve a Xcode y presiona Run nuevamente

---

## 6. Flujo de actualización continua

Cuando realizas cambios en Windows y quieres probarlos en iPhone:

### En Windows

```powershell
# Opción A: script automatizado
.\scripts\verificar-y-publicar.ps1

# Opción B: manual
npm run build
git add --all
git commit -m "Descripción del cambio"
git push origin main
```

### En el Mac (actualizar desde GitHub)

```bash
git pull origin main
npm ci
npm run build
npx cap sync ios
npx cap open ios
# En Xcode: Command + R
```

O simplemente:

```bash
git pull && npm ci && npm run build && npx cap sync ios && npx cap open ios
```

---

## 7. Solución de problemas comunes

### "Node.js no está instalado" en Mac

```bash
# Instalar con nvm (recomendado)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc
nvm install 20
nvm use 20
```

### "xcodebuild not found"

Xcode no está instalado o el path no está configurado:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### "npm ci" falla con error de dependencias

```bash
# Eliminar caché y reinstalar
rm -rf node_modules
npm install
```

### "cap sync" falla: "capacitor.config.ts not found"

Asegúrate de ejecutar el script desde la raíz del proyecto (donde está `package.json`):

```bash
pwd                    # debe mostrar la raíz del proyecto
ls capacitor.config.ts # debe existir
```

### Xcode muestra "Signing certificate not found"

1. En Xcode → Preferences → Accounts: agrega tu Apple ID
2. En Signing & Capabilities: selecciona tu cuenta como Team
3. Haz clic en **Automatically manage signing**

### La app no aparece en el iPhone después de instalar

Revisa si hay error de confianza:
- iPhone → Ajustes → General → VPN y gestión del dispositivo → Confiar en tu Apple ID

### Error "The iOS deployment target is set to X.X, but the range of supported deployment targets is X.X to X.X"

En Xcode, selecciona el proyecto App → Build Settings → busca "iOS Deployment Target" → cambia a iOS 16.0

### "git push" falla con "Authentication failed"

```bash
# En Mac, instala GitHub CLI
brew install gh
gh auth login
# Sigue las instrucciones

# O configura SSH:
ssh-keygen -t ed25519 -C "tu@email.com"
cat ~/.ssh/id_ed25519.pub
# Copia la clave y pégala en GitHub: Settings → SSH and GPG keys → New SSH key
```

### El script verificar-y-publicar.ps1 no ejecuta (política de ejecución)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Confirma con 'S'
```

---

## Scripts de referencia

| Script | Plataforma | Propósito |
|---|---|---|
| `scripts/verificar-y-publicar.ps1` | Windows | Verificar, compilar, commitear y hacer push |
| `scripts/verificar-mac.sh` | macOS | Diagnosticar el entorno antes de instalar |
| `scripts/setup-mac.sh` | macOS | Preparar e instalar el proyecto completo para iOS |

---

## Comandos de referencia rápida

### Windows

```powershell
npm ci                                    # Instalar dependencias
npm start                                 # Servidor de desarrollo (http://localhost:8100)
npm run build                             # Compilar para producción
npx vitest run                            # Ejecutar pruebas
.\scripts\verificar-y-publicar.ps1       # Script automatizado de publicación
```

### macOS

```bash
./scripts/verificar-mac.sh              # Diagnóstico del entorno
./scripts/setup-mac.sh                  # Configurar e iniciar en Xcode
git pull && npm ci && npm run build && npx cap sync ios   # Actualizar desde GitHub
npx cap open ios                         # Abrir en Xcode
```

---

*Ionic 9 · Angular 22 · Capacitor 8 · TypeScript 6*
