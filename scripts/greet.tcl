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

# is this nick an IRC operator? (global oper, e.g. FunT / deemah / lor2demon)
proc greet::is_ircop {nick chan} {
    if {[catch {set r [isircop $nick $chan]}] == 0 && $r} { return 1 }
    if {[onchan $nick $chan]} {
        if {[catch {set fl [getchanflags $nick $chan]}] == 0} {
            if {[string match "*server*" [string tolower $fl]]} { return 1 }
        }
    }
    return 0
}

# ALL welcome messages are SILENT now. boss is the only bot that greets, and
# only real channel operators (+o). WUNDERkind no longer greets anyone on join.
proc greet::on_join {nick uhost hand chan} {
    return
}

putlog "greet.tcl loaded (greeting DISABLED — boss handles op greetings only)."
