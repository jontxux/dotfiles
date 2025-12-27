;; ~/dotfiles/guix/home-configuration.scm
(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (gnu home services)
             (gnu home services shells)
             (gnu home services xdg)
             (guix gexp)
             (ice-9 ftw))

;;; ============================================================================
;;; CONFIGURACIÓN DE RUTAS
;;; ============================================================================

(define %this-file-dir (dirname (current-filename)))
(define %dotfiles-dir (string-append %this-file-dir "/.."))

;;; ============================================================================
;;; HELPERS PARA GESTIÓN DE ARCHIVOS
;;; ============================================================================

(define (sanitize-store-name path)
  "Convierte 'ruta/.archivo' -> 'archivo' para que sea válido en el store."
  (let ((base (basename path)))
    (if (string-prefix? "." base)
        (string-drop base 1) ; Quita el punto inicial
        base)))

(define (config-file path)
  "Crea entrada para ~/.config/PATH"
  (list path (local-file (string-append %dotfiles-dir "/.config/" path)
                         #:recursive? #t)))

(define (home-file path)
  "Crea entrada para ~/PATH. Maneja puntos y rutas correctamente."
  (list path (local-file (string-append %dotfiles-dir "/" path)
                         (sanitize-store-name path))))

(define (home-directory path)
  "Crea entrada recursiva para ~/PATH."
  (list path (local-file (string-append %dotfiles-dir "/" path)
                         (sanitize-store-name path)
                         #:recursive? #t)))

;;; ============================================================================
;;; DEFINICIÓN DE APPS A PORTAR
;;; ============================================================================

;; Apps simples: solo un archivo de config
(define %simple-configs
  '("yt-dlp/config"
    "imv/config"
    "foot/foot.ini"
    "zathura/zathurarc"
    "msmtp/config"
    "newsboat/config"
    "newsboat/urls"))

;; Apps con directorios completos
(define %complex-configs
  '("btop"              ; tiene subdirectorios con themes
    "lf"                ; tiene scripts/ separado
    "mpv"               ; tiene fonts/, scripts/, script-opts/
    "coc"
    ;; "sway"           ; compilado en C, necesita tratamiento especial
    ;; "systemd"        ; servicios, necesita home-shepherd o similar
    ))

;; Dotfiles de la raíz del home (~/)
(define %home-dotfiles
  '(".gitconfig"
    ".aliases"
    ".mbsyncrc"
    ".mozilla/native-messaging-hosts/com.github.browserpass.native.json"
    ;; ".asoundrc"        ; descomenta cuando lo portes
    ))

;; Directorios completos del home que necesitan copiarse recursivamente
(define %home-directories
  '(".vim"                ; vimrc, coc, ultisnips, etc
    ".mutt"               ; muttrc y configuraciones
    ))

;;; ============================================================================
;;; HOME ENVIRONMENT
;;; ============================================================================

(home-environment
  ;;; --------------------------------------------------------------------------
  ;;; PAQUETES
  ;;; --------------------------------------------------------------------------
  (packages (map specification->package
                 '(;; Core
                   "glibc-locales"

                   ;; Shell utilities
                   "eza"
                   "fd"
                   "zoxide"
                   "lf"
                   "diff-so-fancy"
                   "jq"
                   "gron"
                   "pup"
                   "curl"
                   "wget"

                   ;; Wayland/Screenshot
                   "grim"
                   "slurp"
                   "wl-clipboard"
                   "bemenu"

                   ;; Media
                   "yt-dlp"
                   "imv"
                   "mpv"

                   ;; Development
                   "guile"
                   "vim-full"

                   ;; Mail / MTA / News
                   "msmtp"
                   "mutt"
                   "isync"
                   "nss-certs" ;; instalado para que funcione newsboat
                   "newsboat"

                   ;; System / Monitoring
                   "btop"

                   ;; Viewers
                   "zathura"
                   "zathura-pdf-poppler"

                   ;; Multiplexer/Terminal
                   "foot"

                   ;; Security / Password Management
                   "password-store"
                   "browserpass-native"

                   ;; Themes / Icons
                   "adwaita-icon-theme"
                   )))

  ;;; --------------------------------------------------------------------------
  ;;; SERVICIOS
  ;;; --------------------------------------------------------------------------
  (services
   (list
    ;;; ------------------------------------------------------------------------
    ;;; XDG CONFIG FILES (~/.config/*)
    ;;; ------------------------------------------------------------------------
    (simple-service 'xdg-configs
                    home-xdg-configuration-files-service-type
                    (append
                      (map config-file %simple-configs)
                      (map config-file %complex-configs)))

    ;;; ------------------------------------------------------------------------
    ;;; HOME FILES (~/.*)
    ;;; ------------------------------------------------------------------------
    (simple-service 'home-dotfiles
                    home-files-service-type
                    (append
                      (map home-file %home-dotfiles)
                      (map home-directory %home-directories)))

    ;; ------------------------------------------------------------------------
    ;; Variables de entorno para que las apps encuentren el CA bundle de Guix
    ;; (export SSL_CERT_FILE, SSL_CERT_DIR, CURL_CA_BUNDLE, GIT_SSL_CAINFO)
    ;; Ajusta la ruta si usas otro perfil distinto a ~/.guix-home/profile
    (simple-service 'profile-env-vars
                    home-environment-variables-service-type
                    `(("SSL_CERT_DIR" . ,(string-append (getenv "HOME") "/.guix-home/profile/etc/ssl/certs"))
                      ("SSL_CERT_FILE" . ,(string-append (getenv "HOME") "/.guix-home/profile/etc/ssl/certs/ca-certificates.crt"))
                      ("CURL_CA_BUNDLE" . ,(string-append (getenv "HOME") "/.guix-home/profile/etc/ssl/certs/ca-certificates.crt"))
                      ("GIT_SSL_CAINFO" . ,(string-append (getenv "HOME") "/.guix-home/profile/etc/ssl/certs/ca-certificates.crt"))))

    ;;; ------------------------------------------------------------------------
    ;;; SHELL (ZSH)
    ;;; ------------------------------------------------------------------------
    ;; Cuando portes zsh completamente:
    ;; (service home-zsh-service-type
    ;;          (home-zsh-configuration
    ;;           (zshrc (list (local-file (string-append %dotfiles-dir "/.zshrc"))))
    ;;           (zprofile (list (local-file (string-append %dotfiles-dir "/.zprofile"))))))
    )))
