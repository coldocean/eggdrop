# urltitle.tcl — fetch & announce the <title> of URLs posted in channel.
# Uses Tcl's http + tls packages (TLS comes from the openssl-linked build).

if {[catch {package require http}]} {
    putlog "urltitle: http package unavailable, disabling."
    return
}
catch {package require tls}
catch {
    ::http::register https 443 [list ::tls::socket -autoservername true]
}

namespace eval urltitle {
    variable maxbytes 131072   ;# read at most 128 KB
    variable timeout  8000     ;# ms
    variable lastfetch 0       ;# simple rate limit
}

bind pubm - "*http*" urltitle::scan
proc urltitle::scan {nick uhost hand chan text} {
    variable lastfetch
    # rate limit: at most one fetch every 3s network-wide
    if {[expr {[clock milliseconds]-$lastfetch}] < 3000} { return }
    if {![regexp -nocase {(https?://[^\s]+)} $text -> url]} { return }
    set lastfetch [clock milliseconds]
    after 10 [list urltitle::fetch $chan $url]
}

proc urltitle::fetch {chan url} {
    variable maxbytes
    variable timeout
    if {[catch {
        set tok [::http::geturl $url -timeout $timeout -binary 1 \
                    -headers {User-Agent "Mozilla/5.0 (WUNDERkind IRC bot)"} \
                    -progress urltitle::progress]
        set code [::http::ncode $tok]
        set body [::http::data $tok]
        ::http::cleanup $tok
    } err]} {
        putlog "urltitle: fetch failed: $err"
        return
    }
    if {![regexp -nocase {<title[^>]*>(.*?)</title>} $body -> title]} { return }
    # collapse whitespace, decode a few entities, trim
    regsub -all {\s+} $title " " title
    set title [string trim $title]
    set title [string map {&amp; & &lt; < &gt; > &quot; \" &#39; ' &apos; '} $title]
    if {[string length $title] > 200} {
        set title "[string range $title 0 197]..."
    }
    if {$title eq ""} { return }
    putserv "PRIVMSG $chan :\00310\002\[link\]\017 $title"
}

# Abort the download once we have enough bytes (we only need the <head>).
proc urltitle::progress {token total current} {
    variable maxbytes
    if {$current >= $maxbytes} { ::http::reset $token "size limit" }
}

putlog "urltitle.tcl loaded — link titles enabled."
