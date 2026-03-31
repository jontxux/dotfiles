{
  stdenv,
  pkg-config,
  json_c,
  libpulseaudio,
}:

stdenv.mkDerivation {
  pname = "sway-barra";
  version = "1.0";

  # La fuente está en la subcarpeta 'src' junto a este archivo
  src = ./src;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    json_c
    libpulseaudio
  ];

  # Comando de compilación
  buildPhase = ''
    gcc -Wall -O2 -o barra barra.c -lpulse -ljson-c -lpulse-mainloop-glib -lpthread
  '';

  # Instalación
  installPhase = ''
    mkdir -p $out/bin
    cp barra $out/bin/barra
  '';
}
