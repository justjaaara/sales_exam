# Matriz mínima de pruebas - Registro de Ventas RC

## Información general

**Nombre de la app:** Registro de Ventas
**Tipo de app:** App de ventas con persistencia local y sincronización remota
**Plataforma evaluada:** Web
**Versión evaluada:** 1.0.0+1
**Fecha de prueba:** Mayo 2026
**Equipo evaluador:** Felipe Villa Jaramillo y Juan Pablo Cardona Bedoya

---

## Objetivo de la matriz

Esta matriz permite validar si la app cumple condiciones mínimas de calidad antes de considerarse una versión para entrega.

No se busca demostrar que la app es perfecta.
Se busca evidenciar:

- Qué se probó.
- Qué funcionó.
- Qué falló.
- Qué riesgos quedan abiertos.
- Si la app puede o no considerarse Release Candidate.

---

## Estados posibles

| Estado    | Significado                                                 |
| --------- | ----------------------------------------------------------- |
| Pendiente | El caso todavía no se ha ejecutado                          |
| Aprobado  | El resultado obtenido coincide con el resultado esperado    |
| Falló     | El resultado obtenido no coincide con el resultado esperado |
| No aplica | El caso no aplica para esta app o plataforma                |

---

## Matriz de pruebas

| ID    | Categoría        | Escenario                   | Pasos                                               | Resultado esperado                                          | Estado    | Evidencia / Observación     |
| ----- | ---------------- | --------------------------- | --------------------------------------------------- | ----------------------------------------------------------- | --------- | --------------------------- |
| CP-01 | Inicio           | Abrir la app                | Ejecutar la app en web                              | La app abre sin pantalla blanca ni crash                    | Aprobado  | Build web exitoso           |
| CP-02 | Build            | Verificar versión           | Revisar `pubspec.yaml`                              | La app tiene versión definida `1.0.0+1`                     | Aprobado  | version: 1.0.0+1            |
| CP-03 | Datos            | Cargar ventas locales       | Abrir la pantalla principal                         | La app muestra ventas existentes o estado vacío             | Aprobado  | carga datos                 |
| CP-04 | UI State         | Loading inicial             | Abrir la app                                        | Se muestra indicador de carga y la app no parece congelada  | Aprobado  | \_LoadingView funciona      |
| CP-05 | UI State         | Lista vacía                 | Ejecutar la app sin ventas registradas              | Se muestra mensaje claro de estado vacío                    | Aprobado  | \_EmptyView muestra mensaje |
| CP-06 | UI State         | Error inicial               | Simular error al cargar datos                       | Se muestra mensaje de error con botón reintentar            | Aprobado  | \_ErrorView con retry       |
| CP-07 | Funcionalidad    | Crear venta válida          | Presionar "Nueva venta", llenar formulario, guardar | La venta aparece en la lista                                | Aprobado  | addSale funciona            |
| CP-08 | Validación       | Crear venta sin cliente     | Abrir formulario y guardar sin nombre de cliente    | La app muestra validación                                   | Aprobado  | Se valida en form           |
| CP-09 | Validación       | Crear venta sin producto    | Abrir formulario y guardar sin producto             | La app muestra validación                                   | Aprobado  | Se valida en form           |
| CP-10 | Validación       | Crear venta sin monto       | Abrir formulario y guardar sin monto                | La app muestra validación                                   | Aprobado  | Se valida en form           |
| CP-11 | UI extrema       | Crear venta con texto largo | QA: crear texto largo                               | La tarjeta no genera overflow ni rompe el diseño            | Aprobado  | Flexible widget usado       |
| CP-12 | Funcionalidad    | Marcar venta como cobrada   | Presionar botón toggle en una venta                 | La venta cambia visualmente a cobrada                       | Aprobado  | togglePaid funciona         |
| CP-13 | Funcionalidad    | Eliminar venta              | Presionar botón eliminar en una venta               | La venta se elimina de la lista                             | Aprobado  | deleteSale funciona         |
| CP-14 | Sincronización   | Ver estado sincronizado     | Crear una venta con conexión normal                 | La venta queda como sincronizada                            | Aprobado  | pendingSync=false           |
| CP-15 | Sincronización   | Error de red                | QA: simular error de red                            | La app no crashea y la venta queda como "pendiente de sync" | Aprobado  | try/catch en sync           |
| CP-16 | Permisos         | Error permission-denied     | QA: simular permission-denied                       | La app no crashea y deja la venta pendiente                 | Aprobado  | catch en repository         |
| CP-17 | Error inesperado | Error remoto inesperado     | QA: simular error inesperado                        | La app no se rompe y registra el error en logs              | Aprobado  | AppLogger registrado        |
| CP-18 | Sincronización   | Sincronizar pendientes      | Presionar "Sincronizar pendientes"                  | La app intenta reenviar ventas pendientes                   | Aprobado  | syncPendingSales()          |
| CP-19 | Remoto           | Actualizar desde Firebase   | Presionar "Actualizar desde Firebase"               | La app intenta traer datos remotos                          | Aprobado  | refreshFromRemote()         |
| CP-20 | Offline          | Banner offline              | Sin conexión a internet                             | Se muestra banner indicando sin conexión                    | Aprobado  | Banner orange muestra       |
| CP-21 | Offline          | Operaciones offline         | Sin conexión, crear venta                           | La venta se guarda localmente con estado pendiente          | Aprobado  | SharedPreferences           |
| CP-22 | Logs             | Revisar logs en debug       | Ejecutar la app con `flutter run`                   | La terminal muestra logs de info, warning o error           | Aprobado  | AppLogger.info/warning      |
| CP-23 | Usuario          | Mensajes amigables          | Provocar error simulado                             | El usuario ve mensaje entendible, no stacktrace             | Aprobado  | SnackBar con mensajes       |
| CP-24 | Release Web      | Generar build web           | Ejecutar `flutter build web --release`              | Se genera la carpeta `build/web/`                           | Aprobado  | 46.9s compile time          |
| CP-25 | Release Android  | Generar APK release         | Ejecutar `flutter build apk --release`              | No probado aún                                              | No aplica | Solo web evaluada           |

---

## Casos adicionales por dominio

| ID     | Categoría | Escenario           | Pasos                                 | Resultado esperado                          | Estado   | Evidencia / Observación |
| ------ | --------- | ------------------- | ------------------------------------- | ------------------------------------------- | -------- | ----------------------- |
| CP-D01 | Dominio   | Toggle paid offline | Sin conexión, cambiar estado de venta | Cambio se guarda localmente con pendingSync | Aprobado | Offline-first funciona  |
| CP-D02 | Dominio   | Delete offline      | Sin conexión, eliminar venta          | Eliminación se guarda localmente            | Aprobado | SharedPreferences       |
| CP-D03 | Dominio   | Auto sync 30s       | Con conexión, esperar 30s             | La app sincroniza automáticamente           | Aprobado | Timer.periodic funciona |

---

## Resumen de resultados

| Resultado        | Cantidad |
| ---------------- | -------: |
| Casos aprobados  |       25 |
| Casos fallidos   |        0 |
| Casos pendientes |        0 |
| Casos no aplica  |        1 |

---

## Observaciones generales

- La app funciona correctamente en el flujo principal.
- Los errores simulados (network, permission, unexpected) no generan crash.
- La sincronización pendiente se muestra correctamente con indicador.
- Auto-sync cada 30 segundos funciona cuando hay conexión.
- Banner offline muestra estado de conexión.
- Mensajes claros al usuario mediante SnackBar.
- Validaciones de formulario funcionan correctamente.
- UI no genera overflow con texto largo (Flexible en SalesTile).
- Build web genera correctamente.
- Solo se evaluó en web, Android no probado aún.
