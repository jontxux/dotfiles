# Dotfiles de JB

Configuraciones personales sincronizadas con `/etc/nixos`.

## Estructura

```
dotfiles/
├── .aliases              # Aliases de shell actualizados para NixOS
├── .zshrc                # Configuración Zsh con modo VI y prompt personalizado
├── .gitconfig            # Configuración Git
├── .vim/                 # Configuración Vim con plugins y CoC
│   └── vimrc
├── .config/
│   └── sway/
│       └── config        # Configuración Sway (Wayland)
├── .mozilla/
│   └── firefox/
│       └── user.js       # Configuración Firefox (Betterfox)
├── pkgs/
│   └── sway-bar/         # Barra personalizada para sway
│       ├── default.nix   # Definición del paquete Nix
│       └── src/
│           └── barra.c   # Código fuente de la barra
├── scripts/              # Scripts útiles
│   ├── run.sh           # Ejecutar programas en entorno limpio
│   ├── nixsh.sh         # Abrir shell con paquete específico
│   ├── simple-diff.sh   # Comparador de archivos con diff-so-fancy
│   └── instalar-barra.sh # Instalar barra personalizada
└── etc/                  # Configuraciones de sistema
    ├── doas.conf
    ├── pam.d/
    ├── systemd/
    └── udev/
```

## Configuraciones principales

### Shell (Zsh)
- Modo VI con cursor visual
- Prompt personalizado con Git
- Aliases para NixOS (`aplicar`, `probar`, `refrescar`, etc.)
- Integración con fzf, zoxide, direnv

### NixOS
Los aliases más importantes:
- `aplicar` - Aplicar cambios del sistema
- `probar` - Probar cambios sin aplicar
- `refrescar` - Actualizar flake
- `limpiar` - Limpiar caché y generaciones antiguas
- `buscar` - Buscar paquetes
- `conf` - Ir a /etc/nixos
- `nixedit` - Editar configuración NixOS

### Vim
- CoC para autocompletado LSP
- Plugins para productividad (NERDTree, fzf, git, etc.)
- Temas Gruvbox y Everforest
- Configuración optimizada para rendimiento

### Sway (Wayland)
- Teclas estilo Vim (hjkl)
- Barra personalizada con código fuente en `pkgs/sway-bar/`
- Atajos para multimedia y captura de pantalla
- Integración con bemenu, grim, slurp

### Firefox
- Betterfox para optimización
- Configuración de privacidad y rendimiento
- Extensión Gruvbox Dark

## Scripts útiles

### `run.sh`
Ejecuta programas en entorno limpio sin contaminar configuraciones:
```bash
./scripts/run.sh firefox
```

### `nixsh.sh`
Abre shell temporal con paquete específico:
```bash
./scripts/nixsh.sh python3
```

### `simple-diff.sh`
Compara archivos, clipboard o strings con diff-so-fancy:
```bash
./scripts/simple-diff.sh archivo1.txt archivo2.txt
./scripts/simple-diff.sh clip archivo.txt
```

### `instalar-barra.sh`
Compila e instala la barra personalizada de sway:
```bash
./scripts/instalar-barra.sh
```

## Sincronización

Estos dotfiles están sincronizados con la configuración de `/etc/nixos`. Para actualizar:

1. Los cambios en `/etc/nixos` se reflejan aquí
2. Configuraciones específicas de usuario se mantienen en dotfiles
3. Los scripts esenciales de NixOS están incluidos

## Notas

- Sistema: NixOS con flakes y home-manager
- Entorno: Sway (Wayland)
- Editor: Vim con CoC
- Shell: Zsh con modo VI