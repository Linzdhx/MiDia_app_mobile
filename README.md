# Mi Día — Gestor Personal de Tareas

Una aplicación móvil multiplataforma desarrollada con **Ionic 9 + Angular 22 + Capacitor 8**, lista para ejecutarse en web, Android e iOS.

---

## Descripción

**Mi Día** es un gestor personal de productividad que permite organizar actividades diarias, establecer prioridades, definir fechas de vencimiento y visualizar el progreso. Funciona completamente sin conexión a internet.

---

## Tecnologías utilizadas

| Tecnología | Versión |
|---|---|
| Ionic Framework | 9.0.10 |
| Angular | 22.2.3 |
| TypeScript | ~6.0.0 |
| Capacitor | 8.6.0 |
| @capacitor/preferences | 8.x |
| @capacitor/android | 8.x |
| @capacitor/ios | 8.x |
| Node.js (requerido) | ≥ 24.13.1 |
| npm | ≥ 11.8.0 |

---

## Arquitectura del proyecto

```
midia/
├── capacitor.config.ts           # Configuración de Capacitor
├── android/                      # Proyecto Android nativo (Capacitor)
├── src/
│   ├── main.ts                   # Bootstrap standalone Angular
│   ├── index.html
│   ├── global.scss               # Estilos globales
│   ├── theme/
│   │   └── variables.scss        # Paleta de colores y CSS custom props
│   └── app/
│       ├── app.component.ts      # Componente raíz
│       ├── app.routes.ts         # Rutas lazy-loaded
│       ├── core/
│       │   ├── models/
│       │   │   └── tarea.model.ts        # Interfaces TypeScript
│       │   └── services/
│       │       ├── tareas.service.ts     # CRUD + persistencia
│       │       └── configuracion.service.ts  # Tema + nombre usuario
│       ├── shared/
│       │   └── components/
│       │       └── tabs/
│       │           └── tabs.component.ts  # Navegación inferior
│       └── pages/
│           ├── home/             # Pantalla de inicio
│           ├── tasks/            # Listado de tareas
│           ├── task-form/        # Formulario crear/editar
│           ├── statistics/       # Estadísticas
│           └── settings/         # Ajustes
```

### Patrones de arquitectura

- **Componentes standalone** (Angular 22)
- **Signals** de Angular para estado reactivo
- **Lazy loading** de páginas para rendimiento óptimo
- **Separación estricta**: modelos, servicios y presentación independientes
- **Servicio centralizado** `TareasService` — los componentes nunca acceden directamente al storage
- **Reactive Forms** con validaciones en formulario de tarea

---

## Requisitos previos

- **Node.js** v24.13.1 o superior
- **npm** v11 o superior
- **Java JDK 17+** (solo para compilar Android)
- **Android Studio** (solo para compilar Android)
- **macOS + Xcode 15+** (solo para compilar iOS)

> **Nota sobre Node.js**: El Angular CLI 22 requiere formalmente Node.js v24.15.0. Si usas v24.13.1, el proyecto incluye un parche en `node_modules/@angular/cli/src/utilities/node-version.js` que permite la compilación. Si actualizas dependencias con `npm install`, puede que necesites re-aplicar el parche.

---

## Instalación

```bash
# Clonar o copiar el proyecto
cd midia

# Instalar dependencias
npm install
```

---

## Ejecución en Windows (navegador web)

```bash
# Modo desarrollo con hot-reload
npm start
# o bien:
npx ng serve --port 8100

# La app estará disponible en: http://localhost:8100
```

---

## Compilación para producción (web)

```bash
npm run build
# El bundle generado queda en: midia/www/
```

---

## Configuración de Capacitor

El archivo [`capacitor.config.ts`](./capacitor.config.ts) contiene:

```typescript
appId: 'cl.ejemplo.midia'     // Identificador único del paquete
appName: 'Mi Día'              // Nombre visible en el dispositivo
webDir: 'www'                  // Directorio del bundle web
```

---

## Compilación para Android

### Requisitos
- Java JDK 17 o superior
- Android Studio instalado
- Variables de entorno `JAVA_HOME` y `ANDROID_HOME` configuradas

### Pasos

```bash
# 1. Compilar la app web
npm run build

# 2. Sincronizar con Android
npx cap sync android

# 3. Abrir en Android Studio
npx cap open android
```

En Android Studio:
- Conectar un dispositivo Android con USB Debugging habilitado, o usar un emulador
- Clic en **Run ▶** para instalar y ejecutar

---

## Procedimiento para trasladar el proyecto a macOS

1. Copiar la carpeta completa `midia/` al Mac (por ejemplo mediante USB, disco externo, Git, o servicio en la nube).
2. En el Mac, instalar las dependencias del proyecto:

```bash
cd midia
npm install
```

3. Compilar la app:

```bash
npm run build
```

4. Agregar la plataforma iOS (solo la primera vez):

```bash
npx cap add ios
```

5. Sincronizar con iOS:

```bash
npx cap sync ios
```

---

## Apertura en Xcode y compilación para iOS

### Requisitos en macOS
- macOS 13 Ventura o superior
- Xcode 15 o superior (descargado desde Mac App Store)
- Cuenta de desarrollador Apple (gratuita para pruebas en dispositivo propio)

### Pasos

```bash
# Abrir el proyecto en Xcode
npx cap open ios
```

En Xcode:
1. Seleccionar el proyecto **App** en el navegador de la izquierda
2. En **Signing & Capabilities**, seleccionar tu equipo (Apple ID)
3. Cambiar el Bundle Identifier si es necesario: `cl.ejemplo.midia`
4. Conectar el iPhone por cable USB
5. Seleccionar el dispositivo en la barra superior
6. Clic en **Build and Run ▶**

> La primera vez se te pedirá confiar en el desarrollador desde `Ajustes > General > VPN y gestión del dispositivo` en el iPhone.

---

## Funcionalidades implementadas

### Pantalla de inicio
- Saludo personalizado con hora del día
- Fecha actual formateada en español
- Tarjetas de resumen (pendientes / completadas)
- Barra de progreso del día
- Sección "Próximas a vencer" (tareas que vencen en 3 días)
- Lista "Mis tareas de hoy"
- Estado vacío atractivo cuando no hay tareas
- FAB para crear nueva tarea

### Gestión de tareas (CRUD completo)
- Crear, ver, editar y eliminar tareas
- Marcar/desmarcar como completada con deslizamiento o click
- Campos: título, descripción, categoría, prioridad, fecha de vencimiento
- Prioridades: Baja (verde), Media (amarillo), Alta (rojo)
- Categorías: Personal, Trabajo, Estudios, Salud, Otros

### Listado de tareas
- Búsqueda en tiempo real por título
- Filtro por estado (todas / pendientes / completadas)
- Filtro por categoría y prioridad
- Indicador lateral de prioridad por color
- Acciones de deslizamiento: completar, editar, eliminar
- Ordenamiento por fecha de vencimiento

### Formulario de tareas
- Formulario reactivo con validaciones
- Modo crear y modo editar con el mismo componente
- Validación: título obligatorio, máximo 100 caracteres
- Selector visual de prioridad (3 botones con color)
- Selector de fecha nativo con `IonDatetime`
- Toast de confirmación al guardar

### Estadísticas
- Total, completadas y pendientes
- Tasa de finalización con gráfico circular SVG
- Distribución por categoría con barras de progreso
- Datos calculados en tiempo real desde el servicio

### Ajustes
- Nombre de usuario personalizable (persiste entre sesiones)
- Cambio de tema claro/oscuro (persiste entre sesiones)
- Eliminar todas las tareas con confirmación de alerta
- Información de la aplicación (versión, tecnologías, identificador)

### Persistencia
- Almacenamiento vía `@capacitor/preferences` (localStorage en web, nativo en Android/iOS)
- Los datos persisten al cerrar y reabrir la app
- Funciona completamente offline

---

## Preparación para publicación en tiendas

### Google Play Store

| Requisito | Descripción |
|---|---|
| Cuenta de desarrollador | USD 25 pago único en [play.google.com/console](https://play.google.com/console) |
| Bundle ID | `cl.ejemplo.midia` (cambiar por dominio real) |
| Build de producción | `npm run build && npx cap sync android`, luego generar AAB firmado en Android Studio |
| Iconos | 512×512 px PNG en `android/app/src/main/res/` |
| Firma | Keystore generado con `keytool`, configurado en `build.gradle` |
| Capturas | Mínimo 2 capturas por tipo de dispositivo |
| Política de privacidad | URL requerida si la app maneja datos personales |

```bash
# Build de producción para Android
npm run build
npx cap sync android
# Luego en Android Studio: Build > Generate Signed Bundle/APK
```

### Apple App Store

| Requisito | Descripción |
|---|---|
| Cuenta de desarrollador | USD 99/año en [developer.apple.com](https://developer.apple.com) |
| Bundle ID | `cl.ejemplo.midia` registrado en Apple Developer Portal |
| Certificados | Distribution certificate + Provisioning Profile |
| Build | Desde Xcode: Product > Archive, luego Distribute App |
| Iconos | Set completo en `ios/App/App/Assets.xcassets/AppIcon.appiconset/` |
| Capturas | Requeridas para iPhone 6.7" y 6.5" mínimo |
| App Store Connect | Crear ficha en [appstoreconnect.apple.com](https://appstoreconnect.apple.com) |
| Revisión | 24-72 horas de revisión por Apple |

---

## Limitaciones conocidas

1. **Node.js**: El CLI de Angular 22 requiere exactamente Node 24.15.0. El parche en `node-version.js` permite usar 24.13.1.
2. **iOS**: No compilable desde Windows. Requiere macOS + Xcode.
3. **Iconos y splash screen**: Los iconos por defecto de Capacitor están activos. Para producción se deben reemplazar con assets propios.
4. **Pruebas unitarias**: El runner de tests (`vitest`) puede tener incompatibilidades menores con la versión actual de Node. Las pruebas manuales en browser fueron realizadas y son exitosas.

---

## Comandos de referencia rápida

```bash
# Desarrollo web
npm start                          # Inicia servidor en http://localhost:8100

# Build
npm run build                      # Build de producción
npx ng build --configuration=development  # Build de desarrollo

# Capacitor
npx cap sync android               # Sincronizar build con Android
npx cap open android               # Abrir en Android Studio
npx cap sync ios                   # Sincronizar build con iOS (macOS)
npx cap open ios                   # Abrir en Xcode (macOS)
npx cap run android                # Ejecutar directo en dispositivo Android

# Tests
npm test                           # Ejecutar tests unitarios
```

---

## Próximos pasos sugeridos

- [ ] Notificaciones push para tareas por vencer (`@capacitor/push-notifications`)
- [ ] Recordatorios locales (`@capacitor/local-notifications`)
- [ ] Subtareas dentro de cada tarea
- [ ] Exportar/importar tareas (JSON/CSV)
- [ ] Widget de pantalla de inicio (Android/iOS)
- [ ] Sincronización opcional en la nube (Firebase)
- [ ] Modo tablet con diseño de dos columnas
- [ ] Iconos y splash screen personalizados para producción

---

*Desarrollado con Ionic 9 · Angular 22 · Capacitor 8 · TypeScript 6*
