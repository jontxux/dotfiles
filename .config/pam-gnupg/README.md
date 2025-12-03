## Instrucciones rápidas (versión corta)

1. Saca los keygrips de tu clave (primaria y subclave de autenticación `[A`) con:

```
gpg --list-secret-keys --with-keygrip
```

2. Edita `~/.config/pam-gnupg` (o `~/.pam-gnupg`) y pega **un keygrip por línea** (incluye la subclave `[A]` para SSH).

Ejemplo:

```
6F4ABB77A88E922406BCE6627AFEEE2363914B76
FBDEAD7B0C484CDC85F1CF70352833EB0C921D58
```

3. Asegura permisos:

```
chmod 600 ~/.config/pam-gnupg
```

Listo.

