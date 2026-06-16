# greet.tcl — welcome new joiners with a colorful greeting.
# IRC color codes: \003<fg>  bold \002  reset \017

namespace eval greet {
    # per-channel greeting (use %nick% and %chan% placeholders)
    variable msgs
    array set msgs {
        "#lobby"     "\0030,4 \002WELCOME \002 \017\0033 %nick%\017 to \00310#lobby\017! Type \002/motd\017 for rules & commands. Register your nick: \002/msg NickServ REGISTER <pass> <email>\017"
        "#help"      "\0030,2 \002HELP \002 \017\0033%nick%\017 — ask your question and someone will help. Be patient & kind."
        "#wunderbar" "\00313\002Willkommen\017 \0033%nick%\017 auf \002\00304#wunderbar\017! Enjoy the network — by funt of sky & deemah."
    }
    variable default "\0033Welcome %nick%\017 to \00310%chan%\017! Have a great time on \002Wunderbar\017."
}

bind join - * greet::on_join
proc greet::on_join {nick uhost hand chan} {
    variable msgs
    variable default
    # don't greet the bot itself or services
    if {$nick eq $::botnick} { return }
    if {[string match -nocase "*Serv" $nick]} { return }
    set ch [string tolower $chan]
    if {[info exists msgs($ch)]} {
        set m $msgs($ch)
    } else {
        set m $default
    }
    set m [string map [list %nick% $nick %chan% $chan] $m]
    # small delay so the greeting lands after the join is visible
    utimer 1 [list putserv "PRIVMSG $chan :$m"]
}

putlog "greet.tcl loaded."
