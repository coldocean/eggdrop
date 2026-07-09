# ---------------------------------------------------------------------------
# t-2.botanswer.tcl  --  Wunderbar / WUNDERkind
#
# Let BogusTrivia score answers given by OTHER bots (the LLM bot ypoD, etc.).
#
# Why this is needed:
#   * Eggdrop's `pubm` answer bind silently skips messages from users flagged
#     +b (bots) in the userfile, so WUNDERkind never even sees a bot's line.
#   * Even when pubm does fire, TGotIt requires the whole message to be the
#     bare answer word (string equal). ypoD is an LLM and answers inside a
#     full Russian sentence, so an exact-line match can never happen.
#
# This hook binds `raw PRIVMSG` (fires at the server layer, BEFORE any
# bot/ignore filtering), and for a configured list of answer-bot nicks it
# scans their message for any currently-valid answer as a whole word. If it
# finds one it calls TGotIt with just that bare token, so normal scoring runs.
#
# Humans are untouched (they keep scoring through the normal pubm bind); this
# only adds a path for the listed bots, so there is no double-scoring — the
# first correct answer ends the round anyway.
# ---------------------------------------------------------------------------

# Nicks whose sentences should be scanned for embedded answers.
# Override at runtime with env ANSWER_BOTS (space-separated).
set t2(answerbots) {ypoD yp0D AIvan AIv4r AIgar AIg4r DyadyaDJ Dyadya-V-Govno}
if {[info exists ::env(ANSWER_BOTS)] && $::env(ANSWER_BOTS) ne ""} {
  set t2(answerbots) $::env(ANSWER_BOTS)
}

# Escape ARE regex metacharacters in a literal answer string.
proc TReEsc {s} {
  return [regsub -all {[\\^$.\[\]|()*+?{}]} $s {\\&}]
}

proc TRawAns {from keyword text} {
  global t2
  # only while a question is actually running
  if {![info exists t2(-answer)] || $t2(-answer) eq ""} { return 0 }
  if {![info exists t2(-allansls)] || $t2(-allansls) eq ""} { return 0 }

  set nk [lindex [split $from !] 0]
  # only act on configured answer-bots (case-insensitive)
  set lnk [string tolower $nk]
  set match 0
  foreach b $t2(answerbots) { if {[string tolower $b] eq $lnk} { set match 1 ; break } }
  if {!$match} { return 0 }

  # parse "<chan> :<message>"
  set parts [split $text]
  set chan [lindex $parts 0]
  if {![string equal -nocase $chan $t2(chan)]} { return 0 }
  set msg [string range [join [lrange $parts 1 end]] 1 end]
  if {$msg eq ""} { return 0 }
  # strip CTCP markers if any
  set msg [string map [list \001 " "] $msg]

  # find a valid answer appearing as a whole word in the bot's sentence
  set hit ""
  foreach ans $t2(-allansls) {
    if {$ans eq ""} { continue }
    set pat "\\y[TReEsc $ans]\\y"
    if {[catch {regexp -nocase -- $pat $msg} ok]} { continue }
    if {$ok} { set hit $ans ; break }
  }
  if {$hit eq ""} { return 0 }

  # credit it: feed the bare answer token into the normal scorer
  set uh [lindex [split $from !] 1]
  if {$uh eq ""} { set uh "*" }
  set hn [nick2hand $nk]
  if {$hn eq ""} { set hn "*" }
  catch {TGotIt $nk $uh $hn $chan $hit}
  return 0
}

bind raw - PRIVMSG TRawAns

putlog "\00309t-2.botanswer.tcl loaded (answer-bots: $t2(answerbots))\003"
