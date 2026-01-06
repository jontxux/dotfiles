;; ~/dotfiles/guix/home-configuration.scm
(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (gnu home services)
             (gnu home services shells)
             (gnu home services xdg)
             (guix gexp)
             (ice-9 ftw)
             ;; --- Módulos añadidos para paquetes personalizados ---
             (guix packages)
             (guix download)
             (guix build-system copy)
             ;; AÑADIR ESTOS PARA CATT:
             (guix build-system python)    ; Para paquetes setup.py antiguos
             (guix build-system pyproject) ; Para paquetes modernos (poetry/toml)
             ((gnu packages python-xyz) #:select (python-ifaddr python-zeroconf python-click python-tqdm))
             ((gnu packages python-web) #:select (python-requests python-urllib3))
             ((gnu packages protobuf) #:select (python-protobuf))
             ((gnu packages video) #:select (yt-dlp))
             ((guix licenses) #:prefix license:))

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
    ;; ".asoundrc"      ; descomenta cuando lo portes
    ))

;; Directorios completos del home que necesitan copiarse recursivamente
(define %home-directories
  '(".vim"              ; vimrc, coc, ultisnips, etc
    ".mutt"             ; muttrc y configuraciones
    ))

;;; ============================================================================
;;; PAQUETES PERSONALIZADOS
;;; ============================================================================

(define-public go-chromecast
  (package
    (name "go-chromecast")
    (version "0.3.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/vishen/go-chromecast/releases/download/v"
                           version "/go-chromecast_Linux_x86_64.tar.gz"))
       (sha256
        (base32 "0zcrp6rv8jjkbg3vj877y4rgqjq35xid1vspy02ig2m5y8ag2ndn"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("go-chromecast" "bin/"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'install-completions
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (zsh-completion-dir (string-append out "/share/zsh/site-functions"))
                    (bin (string-append out "/bin/go-chromecast")))
               ;; Crear directorio para completions de zsh
               (mkdir-p zsh-completion-dir)
               ;; Generar y guardar el completion de zsh
               (with-output-to-file (string-append zsh-completion-dir "/_go-chromecast")
                 (lambda ()
                   (invoke bin "completion" "zsh")))
               #t))))))
    (home-page "https://github.com/vishen/go-chromecast")
    (synopsis "CLI for Google Chromecast")
    (description "Herramienta de línea de comandos para enviar medios a Chromecast.")
    (license license:asl2.0)))

;; 1. Dependencia de pychromecast (no suele estar en Guix base)
(define python-casttube
  (package
    (name "python-casttube")
    (version "0.2.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "casttube" version))
              (sha256
               (base32 "10pw2sjy648pvp42lbbdmkkx79bqlkq1xcbzp1frraj9g66azljl"))))
    (build-system python-build-system)
    (arguments
     '(#:tests? #f)) ; Desactivar tests
    (native-inputs (list python-requests))
    (home-page "https://github.com/ur1katz/casttube")
    (synopsis "Interact with the YouTube Chromecast API")
    (description "Librería para interactuar con la API de YouTube en Chromecast.")
    (license license:expat)))

;; 2. Dependencia principal de CATT
(define python-pychromecast
  (package
    (name "python-pychromecast")
    (version "13.0.7") ; Versión compatible y estable
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "PyChromecast" version))
              (sha256
               (base32 "09031hf8a4lp68jf1jjar90sjnqdmck63cgg87fnjcp4bfg8xs8d"))))
    (build-system pyproject-build-system)
    (arguments
     '(#:tests? #f)) ; Desactivar tests
    (native-inputs
     (list (specification->package "python-setuptools")))
    (propagated-inputs
     (list python-casttube
           python-protobuf
           python-zeroconf
           python-requests
           python-ifaddr))
    (home-page "https://github.com/home-assistant-libs/pychromecast")
    (synopsis "Library for Python 3 to communicate with the Google Chromecast")
    (description "Librería de Python para comunicarse con Google Chromecast.")
    (license license:expat)))

;; 3. La aplicación CATT (Traducida de tu PKGBUILD)
(define-public catt
  (package
    (name "catt")
    (version "0.13.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/skorokithakis/catt/archive/refs/tags/v"
                                  version ".tar.gz"))
              (sha256
               (base32 "0nka8zc6sicl6pwlyf8380vwah06fqbrha1j2nw6n0i6ijqh0ar1"))))
    (build-system pyproject-build-system)
    (arguments
     '(#:tests? #f)) ; Desactivamos tests porque requieren red
    (native-inputs
     (list (specification->package "python-poetry-core"))) ; Build system del PKGBUILD
    (propagated-inputs
     (list python-click
           python-ifaddr
           python-requests
           python-pychromecast ; Nuestro paquete definido arriba
           yt-dlp))
    (home-page "https://github.com/skorokithakis/catt")
    (synopsis "Cast All The Things")
    (description "Envía vídeos desde muchas fuentes online a tu Chromecast.")
    (license license:bsd-2)))

;;; ============================================================================
;;; HOME ENVIRONMENT
;;; ============================================================================

(home-environment
  ;;; --------------------------------------------------------------------------
  ;;; PAQUETES
  ;;; --------------------------------------------------------------------------
  ;; Usamos 'append' para mezclar tu paquete personalizado con los del sistema
  (packages
   (append
    ;; 1. Tus paquetes personalizados
    (list go-chromecast
          catt)

    ;; 2. Paquetes oficiales de Guix
    (map specification->package
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

           ;; Window Management
           "i3-autotiling"

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
           ))))

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
    (simple-service 'profile-env-vars
                    home-environment-variables-service-type
                    `(("SSL_CERT_DIR" . ,(string-append (getenv "HOME") "/.guix-home/profile/etc/ssl/certs"))
                      ("SSL_CERT_FILE" . ,(string-append (getenv "HOME") "/.guix-home/profile/etc/ssl/certs/ca-certificates.crt"))
                      ("CURL_CA_BUNDLE" . ,(string-append (getenv "HOME") "/.guix-home/profile/etc/ssl/certs/ca-certificates.crt"))
                      ("GIT_SSL_CAINFO" . ,(string-append (getenv "HOME") "/.guix-home/profile/etc/ssl/certs/ca-certificates.crt"))))

    ;;; ------------------------------------------------------------------------
    ;;; SHELL (ZSH)
    ;;; ------------------------------------------------------------------------
    ;; (service home-zsh-service-type ...)
    )))
