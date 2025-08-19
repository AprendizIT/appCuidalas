# Configuración de Variables de Entorno - Cuídalas App

## Configuración de Credenciales de Odoo

Para usar la integración con Odoo, configura las siguientes variables de entorno:

### Opción 1: Variables de entorno del sistema (Recomendado para producción)

```bash
export ODOO_URL="https://healthgroup-test2-22479070.dev.odoo.com"
export ODOO_DATABASE="healthgroup-test2-22479070"
export ODOO_USERNAME="tu_usuario@empresa.com"
export ODOO_PASSWORD="tu_contraseña_segura"
```

### Opción 2: Para desarrollo local

1. Edita el archivo `lib/core/config/environment_config.dart`
2. Actualiza las constantes `_devUsername` y `_devPassword`:

```dart
static const String _devUsername = 'tu_usuario@empresa.com';
static const String _devPassword = 'tu_contraseña_segura';
```

⚠️ **IMPORTANTE**: Nunca commitees credenciales reales en el código fuente.

## Modo de prueba

Si las credenciales no están configuradas, la app automáticamente usará datos mock para desarrollo.

Para forzar el modo mock:

```dart
PacienteService.setMockMode(true);
```

## Campos mapeados del modelo hms.patient

- **Cédula**: `vat`
- **Nombre**: `name`
- **Edad**: `edad_anhos`
- **EPS/Afiliación**: `eps` (válido si contiene "CAJACOPI EPS S.A.S.")
- **Teléfono**: `mobile`
- **Email**: `email`
- **Último examen**: Por implementar

## Ejecución

```bash
flutter pub get
flutter run
```
