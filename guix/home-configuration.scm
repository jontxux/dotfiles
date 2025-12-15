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

; (define (config-file path)
;   "Crea entrada para ~/.config/PATH desde dotfiles/.config/PATH"
;   (list path (local-file (string-append %dotfiles-dir "/.config/" path))))
(define (config-file path)
  "Crea entrada para ~/.config/PATH desde dotfiles/.config/PATH"
  (list path (local-file (string-append %dotfiles-dir "/.config/" path)
                         #:recursive? #t))) ;; Usa recursive #t si apuntas a carpetas

(define (home-file path)
  "Crea entrada para ~/PATH desde dotfiles/PATH"
  (list path (local-file (string-append %dotfiles-dir "/" path))))

;;; ============================================================================
;;; DEFINICIÓN DE APPS A PORTAR
;;; ============================================================================

;; Apps simples: solo un archivo de config
(define %simple-configs
  '("yt-dlp/config"
    "imv/config"
    "foot/foot.ini"
    "zathura/zathurarc"
    "msmtp/config"))

;; Apps con directorios completos (para portar más adelante)
(define %complex-configs
  '("btop"              ; tiene subdirectorios con themes
    "lf"                ; tiene scripts/ separado
    "mpv"               ; tiene fonts/, scripts/, script-opts/
    ;; "sway"              ; compilado en C, necesita tratamiento especial
    ;; "systemd"           ; servicios, necesita home-shepherd o similar
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

                   ;; Wayland/Screenshot
                   "grim"
                   "slurp"

                   ;; Media
                   "yt-dlp"
                   "imv"
                   "mpv"

                   ;; Development
                   "guile"

                   ;; Mail / MTA
                   "msmtp"

                   ;; System / Monitoring
                   "btop"

                   ;; Viewers
                   ;; "zathura"
                   ;; "zathura-pdf-mupdf"

                   ;; Multiplexer/Terminal
                   "foot"
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
                      (map config-file %complex-configs))) ;; Añadimos las complejas aquí

    ;;; ------------------------------------------------------------------------
    ;;; HOME FILES (~/.*)
    ;;; ------------------------------------------------------------------------
    ;; Cuando portes dotfiles de la raíz (.zshrc, .aliases, etc)
    ;; (simple-service 'home-dotfiles
    ;;                 home-files-service-type
    ;;                 (map home-file
    ;;                      '(".aliases"
    ;;                        ".gitconfig"
    ;;                        ".asoundrc"
    ;;                        ".mbsyncrc")))

    ;;; ------------------------------------------------------------------------
    ;;; SHELL (ZSH)
    ;;; ------------------------------------------------------------------------
    ;; Cuando portes zsh completamente:
    ;; (service home-zsh-service-type
    ;;          (home-zsh-configuration
    ;;           (zshrc (list (local-file (string-append %dotfiles-dir "/.zshrc"))))
    ;;           (zprofile (list (local-file (string-append %dotfiles-dir "/.zprofile"))))))
    )))
