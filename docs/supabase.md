# Supabase para Listix

SQLite sigue siendo la fuente local de verdad. Solo las listas marcadas como compartidas generan operaciones pendientes para PostgreSQL. El cliente Flutter usa Anonymous Auth y la clave pública del proyecto; nunca se debe incluir la clave `service_role` en la aplicación.

## Preparar el proyecto

1. Crea proyectos separados de Supabase para development, preview y production.
2. En cada proyecto activa **Anonymous Sign-Ins** en Authentication > Providers > Anonymous Sign-Ins. La configuración del CLI solo aplica al Supabase local; los proyectos alojados deben habilitar el proveedor desde el Dashboard.
3. Instala Supabase CLI, inicia sesión y enlaza el proyecto elegido:

   ```sh
   supabase login
   supabase link --project-ref <project-ref>
   supabase db push
   ```

   `supabase db push` aplica las migraciones de `supabase/migrations/`. Para desarrollo local también se puede ejecutar `supabase start` y después `supabase db reset`.

4. Copia la Project URL y la clave pública `anon` (o publishable key compatible) desde los ajustes API del proyecto. No uses la clave `service_role`.

## Configurar Flutter por entorno

Pasa los valores al compilar/ejecutar, sin guardarlos en el repositorio:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-anon-or-publishable-key>
```

Usa los valores del proyecto de development en desarrollo, los del proyecto aislado de preview en builds de preview y los de production únicamente en el build de publicación. Configura las mismas dos variables como secretos/variables del pipeline de CI para cada entorno y pásalas como `--dart-define` al comando `flutter build`. Si no se pasan, Listix conserva el modo local y SQLite.

## Compartir y unirse

Al compartir una lista, el cliente genera un token aleatorio, envía únicamente su SHA-256 a `create_list_invite` y comparte `https://listix.app/join/<token>` mediante el selector nativo de Android. El RPC verifica rol y expiración. `join_list_by_token` valida el hash, agrega al usuario de Anonymous Auth y hace cumplir el máximo de cinco miembros en la transacción. La lista se descarga a SQLite; Realtime invalida/recarga esa copia local.

El intent filter está configurado para Android, pero los enlaces HTTPS verificados requieren publicar `https://listix.app/.well-known/assetlinks.json` con el application ID y la huella SHA-256 del certificado de firma de la app. Hasta que el dominio quede verificado, Android puede abrir el enlace en el navegador y se puede pegar el link en la opción “Unirse a una lista”.

## Prueba manual con dos dispositivos

1. Instala el mismo build de desarrollo en dos dispositivos, configurado con el mismo proyecto Supabase. Confirma que Anonymous Sign-Ins esté activo.
2. En el dispositivo A, crea una lista, abre Compartir y activa la colaboración; crea y comparte el link.
3. En el dispositivo B, abre el link o pégalo en “Unirse a una lista”. Verifica que la lista y sus elementos aparezcan localmente.
4. Añade y marca un elemento en A; con ambos conectados, comprueba que B lo recibe. Repite en B y confirma el cambio en A.
5. Desconecta B, modifica la lista y elimina un elemento; reconecta y comprueba que las operaciones pendientes se sincronicen y que el eliminado no reaparezca.
6. Repite desde dispositivos/cuentas anónimas hasta llegar a cinco miembros. Un sexto intento debe ser rechazado por el RPC. Genera otro link y confirma que el anterior deje de admitir nuevos usuarios; los miembros ya incorporados conservan acceso después de la expiración.

Cada instalación conserva una identidad anónima local. Borrar datos/reinstalar crea otra identidad, que cuenta como otro miembro.
