config.load_autoconfig()
c.content.blocking.enabled = True
c.colors.webpage.preferred_color_scheme = 'dark'

# Establecer el motor de búsqueda predeterminado
config.set('url.searchengines', {'DEFAULT': 'https://duckduckgo.com/?q={}'})

# Configurar motores de búsqueda personalizados en Qutebrowser
c.url.searchengines['aes'] = 'https://www.amazon.es/s?k={}'
c.url.searchengines['g'] = 'https://www.google.es/search?q={}'
c.url.searchengines['maps'] = 'https://www.google.com/maps/search/{}'
c.url.searchengines['osm'] = 'https://www.openstreetmap.org/search?query={}'
c.url.searchengines['yt'] = 'https://yewtu.be/search?q={}'
c.url.searchengines['wes'] = 'https://es.wikipedia.org/wiki/{}'
c.url.searchengines['esenw'] = 'https://www.wordreference.com/es/en/translation.asp?spen={}'
c.url.searchengines['enesw'] = 'https://www.wordreference.com/es/translation.asp?tranword={}'
c.url.searchengines['eseu'] = 'https://hiztegiak.elhuyar.eus/es_eu/{}'
c.url.searchengines['eues'] = 'https://hiztegiak.elhuyar.eus/eu/{}'
c.url.searchengines['enes'] = 'https://translate.google.com/#en/es/{}'
c.url.searchengines['esen'] = 'https://translate.google.com/#es/en/{}'


# Añadir motores de búsqueda para GitHub y Gist
c.url.searchengines['git'] = 'https://github.com/search?q={}'
c.url.searchengines['gist'] = 'https://gist.github.com/search?q={}'
c.url.start_pages = ['https://chat.openai.com']

c.content.cookies.accept = 'no-3rdparty'
c.content.headers.do_not_track = True

config.bind(',m', 'spawn mpv {url}')
config.bind(',f', 'spawn firefox {url}')
config.bind(',d', 'spawn yt-dlp -P "/tmp/" {url}')

# from qutebrowser.api import interceptor
# import re

# def redirect_youtube(info: interceptor.Request):
#    """Redirect YouTube requests to Invidious using regular expressions."""
#    url = info.request_url.toString()
#    youtube_regex = re.compile(r'^(?:http[s]?://)?(?:www\.)?youtube\.com/watch\?v=([\w-]+)(&?.*)$')
#    youtu_be_regex = re.compile(r'^(?:http[s]?://)?youtu\.be/([\w-]+)(\?.*)?$')
#
#    youtube_match = youtube_regex.match(url)
#    youtu_be_match = youtu_be_regex.match(url)
#
#    if youtube_match:
#        video_id = youtube_match.group(1)
#        params = youtube_match.group(2)
#        new_url = f"https://invidious.io/watch?v={video_id}{params}"
#        info.redirect(new_url)
#    elif youtu_be_match:
#        video_id = youtu_be_match.group(1)
#        params = youtu_be_match.group(2) if youtu_be_match.group(2) else ""
#        new_url = f"https://invidious.io/watch?v={video_id}{params}"
#        info.redirect(new_url)

#interceptor.register(redirect_youtube)
