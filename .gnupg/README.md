## Añadir claves GPG para uso como SSH

Para permitir que una clave GPG funcione como clave SSH, añade su **Keygrip** al archivo. **Normalmente es el Keygrip de la subclave marcada como `[A]` (Autenticación)**:

```
~/.gnupg/sshcontrol
```

➡ **Una sola línea por cada clave**.

Ejemplo de formato:

```
A1B2C3D4E5F67890123456789ABCDEF123456789
```

Para obtener el Keygrip:

```
gpg --list-secret-keys --with-keygrip
```

⚠ Este archivo **no debe subirse a repositorios** y debe tener permisos:

```
chmod 600 ~/.gnupg/sshcontrol
```
