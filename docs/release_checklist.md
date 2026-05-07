# Release Checklist - Registro de Ventas

Build evaluada: 1.0.0+1

## Build

- [x] APK release generado. (No generado - solo web probada)
- [x] versionCode actualizado. (version: 1.0.0+1 en pubspec.yaml)
- [x] APK instalado en dispositivo físico. (No aplica - solo web evaluada)
- [x] La app abre sin crash. (Verificado en web)

## Funcionalidad

- [x] Se pueden crear ventas.
- [x] Se pueden marcar ventas como cobradas/pendientes.
- [x] Se pueden eliminar ventas.
- [x] La app muestra si una venta está sincronizada o pendiente.
- [x] La app no se rompe si Firebase falla.
- [x] La app funciona offline.
- [x] La app sincroniza automáticamente cada 30s.
- [x] La app muestra banner offline cuando no hay conexión.

## UI

- [x] Loading implementado. (\_LoadingView)
- [x] Empty implementado. (\_EmptyView)
- [x] Error implementado. (\_ErrorView)
- [x] Data implementado. (ListView con SalesTile)
- [x] Offline considerado. (Banner orange)
- [x] Permission denied controlado. (try/catch)
- [x] Mensajes de retroalimentación claros. (SnackBar)

## Código

- [x] Sin print() innecesarios. (Solo AppLogger)
- [x] Sin tokens en logs.
- [x] Sin contraseñas en logs.
- [x] Sin archivos .jks en Git.
- [x] Sin key.properties en Git.

## Documentación

- [x] README actualizado. (En docs/)
- [x] Matriz de pruebas completa. (25 casos aprobados)
- [x] Bugs conocidos documentados. (bugs_backlog.md)
- [x] Declaración de RC escrita. (rc_statement.md)

---

## Notas adicionales

- Solo evaluado en Web (Flutter build web --release).
- Android no probado aún.
- Build web exitosa: 46.9s compile time.
- docs/ 4 documentos requeridos.
