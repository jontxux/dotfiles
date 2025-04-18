#!/usr/bin/perl

use strict;
use warnings;
use JSON::PP;
use utf8;
binmode STDOUT, ':utf8';

# Configuración inicial
my $URL = "https://www.eitb.eus/es/television/programas/el-conquistador/capitulos-completos/";

# Seleccionar tipo de video
my $bemenu_cmd = q{printf "episodio\ndebate" | bemenu -H 23 -i} 
               . q{ --tb='#323232' --tf='#bbbbbb'}
               . q{ --fb='#323232' --ff='#bbbbbb'}
               . q{ --nb='#323232' --nf='#bbbbbb'}
               . q{ --hb='#005577' --hf='#eeeeee'}
               . q{ --sb='#323232' --sf='#bbbbbb'}
               . q{ --ab='#323232' --af='#bbbbbb'}
               . q{ -p 'Selecciona tipo de video: '};

my $selection = `$bemenu_cmd`;
chomp $selection;
die "Selección no válida\n" unless $selection =~ /^(episodio|debate)$/;

# Obtener enlaces de video
my $content = `curl -s "$URL"`;
my @a_tags;
while ($content =~ /<a[^>]*title="T21[^>]*>/gi) {
    push @a_tags, $&;
}

# Filtrar por selección
@a_tags = grep { $selection eq 'debate' ? /debate/i : !/debate/i } @a_tags;

# Extraer títulos
my @titles;
foreach my $tag (@a_tags) {
    $tag =~ /data-titulovideo="([^"]*)"/ && push @titles, $1;
}

# Seleccionar video específico
my $titles_str = join "\n", @titles;
my $bemenu_select = q{echo "$titles_str" | bemenu -i -l 20 -H 23}
                  . q{ --tb='#323232' --tf='#bbbbbb'}
                  . q{ --fb='#323232' --nb='#323232' --nf='#bbbbbb'}
                  . q{ --hb='#005577' --hf='#eeeeee'}
                  . q{ --sb='#323232' --sf='#bbbbbb'}
                  . q{ -p 'Selecciona el episodio: '};

my $video_title = `$bemenu_select`;
chomp $video_title;
die "No se seleccionó ningún video\n" unless $video_title;

# Obtener ID del video
my ($video_id) = map { /id="(\d+)"/ && $1 } 
                 grep { /data-titulovideo="\Q$video_title\E"/i } @a_tags;
die "No se encontró ID del video\n" unless $video_id;

# Obtener detalles del video
my $video_details = `curl -s "https://mam.eitb.eus/mam/REST/ServiceMultiweb/Video4/MULTIWEBTV/$video_id/"`;
my $json = decode_json($video_details);
my $rendition = first { 
    $_->{FRAME_WIDTH} == 1280 && $_->{FRAME_HEIGHT} == 720 
} @{$json->{web_media}[0]{RENDITIONS}};
die "No se encontró URL del video\n" unless $rendition;
my $video_url = $rendition->{PMD_URL};

# Seleccionar ruta de descarga
my $bemenu_ruta = q{printf "usb\ntmp\ndescargas" | bemenu -H 23 -i}
                . q{ --tb='#323232' --tf='#bbbbbb'}
                . q{ --fb='#323232' --ff='#bbbbbb'}
                . q{ --nb='#323232' --nf='#bbbbbb'}
                . q{ --hb='#005577' --hf='#eeeeee'}
                . q{ --sb='#323232' --sf='#bbbbbb'}
                . q{ --ab='#323232' --af='#bbbbbb'}
                . q{ -p 'Introduce la ruta de descarga: '};

my $ruta = `$bemenu_ruta`;
chomp $ruta;

my %rutas = (
    usb    => '/media/usb',
    tmp    => '/tmp',
    descargas => "$ENV{HOME}/Descargas"
);
my $ruta_descarga = $rutas{$ruta} || die "Ruta no válida\n";

# Generar nombre de archivo
(my $nombre_archivo = $video_title) =~ tr/ ()/_/;
$nombre_archivo .= '.mp4';
my $archivo = "$ruta_descarga/$nombre_archivo";

# Descargar si no existe
if (-e $archivo) {
    print "El archivo ya existe: $archivo\n";
} else {
    system("curl", "-sLo", $archivo, $video_url) == 0 
        or die "Error al descargar: $!\n";
    print "Descarga completada: $archivo\n";
}

sub first(&@) {
    my $code = shift;
    $_ && $code->() and return $_ for @_;
    return undef;
}
