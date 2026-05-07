# Declaración de Release Candidate - Registro de Ventas RC

## Información general

**Nombre de la app:** Registro de Ventas
**Versión evaluada:** 1.0.0+1
**Plataforma evaluada:** Web
**Fecha de evaluación:** Mayo 2026
**Equipo evaluador:** Felipe Villa Jaramillo

---

## ¿Qué es una Release Candidate?

Una Release Candidate, o RC, es una versión a entrega.

No significa que la app sea perfecta.
Significa que la app ya tiene una calidad mínima suficiente para ser evaluada como posible versión de entrega.

Una build puede considerarse RC si:

- El flujo principal funciona.
- No hay bugs bloqueantes abiertos.
- La versión está definida.
- La app puede ejecutarse o instalarse correctamente.
- Los estados principales de UI están considerados.
- Los errores esperables se manejan de forma controlada.
- Existe evidencia mínima de pruebas.
- Los bugs conocidos están documentados y priorizados.

---

## Criterios mínimos para declarar RC

| Criterio                                                  | Estado   | Observación                         |
| --------------------------------------------------------- | -------- | ----------------------------------- |
| La app abre sin crash                                     | Aprobado | Build web exitoso                   |
| La versión está definida en `pubspec.yaml`                | Aprobado | version: 1.0.0+1                    |
| El flujo principal funciona                               | Aprobado | Create, read, update, delete OK     |
| La app permite crear ventas válidas                       | Aprobado | Form validation works               |
| La app valida ventas sin campos requeridos                | Aprobado | Required validators                 |
| La app muestra estado Loading                             | Aprobado | \_LoadingView                       |
| La app muestra estado Empty                               | Aprobado | \_EmptyView                         |
| La app muestra estado Error                               | Aprobado | \_ErrorView con retry               |
| La app muestra estado Data                                | Aprobado | ListView con SalesTile              |
| La app maneja errores sin mostrar stacktrace al usuario   | Aprobado | try/catch + SnackBar                |
| La app registra logs técnicos útiles                      | Aprobado | AppLogger.info/warning/error        |
| La app maneja fallos remotos sin perder datos locales     | Aprobado | Offline-first con SharedPreferences |
| La app muestra ventas pendientes de sincronización        | Aprobado | Badge pendingSync                   |
| La app funciona offline                                   | Aprobado | SharedPreferences persistence       |
| La matriz mínima de pruebas fue ejecutada                 | Aprobado | 25 casos aprobados                  |
| No hay bugs P1 abiertos                                   | Aprobado | BUG-01 no bloqueante                |
| Los bugs P2 y P3 están documentados                       | Aprobado | backlog actualizado                 |
| El README o instrucciones de ejecución están actualizados | Aprobado | En docs/                            |

---

## Resultado de la evaluación

Marcar una opción:

- [x] Esta build ES candidata a RC-1.
- [ ] Esta build NO ES candidata a RC-1 todavía.

---

## Justificación

La build `1.0.0+1` puede considerarse **RC-1** porque:

- El flujo principal (CRUD) funciona correctamente en web.
- Los 4 estados mínimos de UI están implementados (loading, empty, error, data).
- La persistencia local funciona con SharedPreferences.
- La sincronización con Firebase implementa estrategia offline-first.
- Los errores simulados (network, permission, unexpected) no generan crash.
- Los mensajes al usuario son claros mediante SnackBar.
- Los logs registran eventos sin exponer información sensible.
- No hay bugs P1 que bloqueen el funcionamiento.
- Los bugs conocidos están documentados y priorizados.
- La matriz de pruebas fue ejecutada con 25 casos aprobados.

---

## Bugs encontrados

| ID     | Título                             | Prioridad | Estado  | Impacto en la RC               |
| ------ | ---------------------------------- | --------- | ------- | ------------------------------ |
| BUG-01 | Permission denied mensaje no claro | P1        | Abierto | No bloqueante - solo afecta UX |
| BUG-02 | Texto largo puede overflow         | P2        | Abierto | No bloqueante - visual         |
| BUG-03 | No probado en Android              | P3        | Abierto | No evaluado - no aplica        |
| BUG-04 | Sin indicador de progreso sync     | P3        | Abierto | Mejora menor                   |

---

## Clasificación de prioridades

| Prioridad | Significado                                                  | ¿Bloquea RC? |
| --------- | ------------------------------------------------------------ | ------------ |
| P1        | Bloquea el flujo principal, causa crash, pérdida de datos    | Sí           |
| P2        | Afecta una funcionalidad importante, pero existe alternativa | Depende      |
| P3        | Error menor, visual o mejora secundaria                      | No           |

---

## Riesgos conocidos

- Solo se evaluó en plataforma web, no en Android físico.
- El mensaje de error cuando Firebase rechaza permisos no es específico.
- No hay indicador visual de progreso durante sincronización.
- La estrategia de sync usa timer de 30s, no detecta cambios inmediatos.

---

## Evidencia usada para la decisión

| Evidencia          | Ubicación o descripción                     |
| ------------------ | ------------------------------------------- |
| Matriz de pruebas  | docs/matriz_pruebas.md - 25 casos aprobados |
| Logs observados    | Terminal durante ejecución                  |
| Build web generada | build/web/ - 46.9s compile                  |
| Backlog de bugs    | docs/bugs_backlog.md                        |

---

## Declaración final

La build `1.0.0+1` puede considerarse **RC-1** porque:

- Cumple todos los requisitos funcionales mínimos del examen.
- Implementa persistencia local con SharedPreferences (estructurada).
- Implementa persistencia remota con Firebase/Firestore.
- Estrategia offline-first funciona correctamente.
- Estados de UI mínimos implementados.
- Manejo de errores controlado sin exponer stacktrace.
- Documentación completa entregada.
- No hay bugs P1 que impidan la entrega.

---

## Próximos pasos

- Probar en dispositivo físico Android.
- Generar APK release.
- Configurar reglas de Firestore correctamente.
- Considerar agregar indicador de progreso durante sync.
- Mejorar mensaje de error cuando hay permission denied.
