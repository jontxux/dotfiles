#!/usr/bin/perl
use strict;
use warnings;
use URI;

# Verifica si la URL se pasó como argumento
my $url = shift; # Intenta obtener el argumento

# Si no hay argumento, verifica si hay datos en el pipe
unless ($url) {
    if (-p STDIN) {  # Verifica si hay un pipe conectado a la entrada estándar
        chomp($url = <STDIN>);
    } else {
        die "Uso: $0 <URL> o proporciona una URL mediante un pipe.\n";
    }
}

# Intenta crear un objeto URI a partir de la URL
my $uri = URI->new($url);

# Verifica si la URL es válida
unless ($uri->scheme && $uri->host) {
    die "La URL proporcionada no es válida: $url\n";
}

# Detecta si es una URL de Amazon
if ($uri->host =~ /amazon\.(\w+)/) {
    my $tld = $1;  # Captura el dominio de nivel superior

    # Si contiene parámetros de búsqueda
    if ($uri->query_param('k')) {
        # Conserva solo el parámetro 'k' (el término de búsqueda)
        my $search_term = $uri->query_param('k');
        my $clean_search_url = URI->new("https://www.amazon.$tld/s");
        $clean_search_url->query_form(k => $search_term);
        print $clean_search_url->as_string, "\n";
        exit;
    }

    # Extrae el identificador del producto si está presente
    if ($uri->path =~ m{/dp/([\w\-]+)}) {
        my $product_id = $1;
        print "https://www.amazon.$tld/dp/$product_id\n";
        exit;
    }
    # Caso especial: short URL (ejemplo: amazon.es/gp/product/)
    elsif ($uri->path =~ m{/gp/product/([\w\-]+)}) {
        my $product_id = $1;
        print "https://www.amazon.$tld/dp/$product_id\n";
        exit;
    }
}

# Para URLs que no son de Amazon, elimina la query
$uri->query(undef);

# Imprime la URL limpia si no tiene un formato específico
print $uri->as_string, "\n";
