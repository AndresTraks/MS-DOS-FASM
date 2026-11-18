# Waiting for the guest, for the tests that start a machine.
#
# A test drives QEMU's monitor down a pipe, so what it sends the machine is
# what it writes on standard output and it never reads anything back.  That
# leaves it nothing to wait on but a length of time, and the length has to be
# the worst case the test will ever be run on.
#
# The waits below close the loop instead.  They ask the monitor to write the
# text screen out -- pmemsave, which every test already uses to read the
# result -- and read it back, so that "the machine has got this far" is
# something the test can see.  The screen is the one thing every machine here
# has, and once an AUTOEXEC.BAT has run out the last line of it is
# COMMAND.COM's prompt, which is the end of nearly every run.
#
# Each of these writes its monitor commands on standard output, the way the
# rest of the pipeline does, and leaves the screen it last read in $SEEN.  A
# test sources this after it has made $OUT.
#
# Giving up is not an error here: the test's own checks say what was missing,
# and they say it better than a wait can.  AWAIT_TIMEOUT is how long to try,
# and it is long because nothing is paid for it when the guest answers: two
# minutes is for the machine that is busy with something else, not for the
# machine that is working.
AWAIT_TIMEOUT=${AWAIT_TIMEOUT:-120}
SHOT=$OUT/await.bin
SEEN=$OUT/await.txt
: > "$SEEN"

# snap: read the text screen into $SEEN.  pmemsave writes the dump itself, so
# the file is gone and then back at its full size; until it is all there,
# what is in $SEEN is the screen from before.
_size() {
    if [ -f "$1" ]; then wc -c < "$1"; else echo 0; fi
}

snap() {
    rm -f "$SHOT"
    echo "pmemsave 0xb8000 4000 \"$SHOT\""
    _n=0
    while [ "$(_size "$SHOT")" -ne 4000 ]; do
        _n=$((_n + 1))
        [ "$_n" -gt 100 ] && return
        sleep 0.05
    done
    python3 tests/screen.py "$SHOT" > "$SEEN"
}

# await TEXT [TIMES]: until TEXT is on the screen, on TIMES lines of it.  A
# machine that is asked the same question twice has the first one still on the
# screen when the second is asked, so the count is how the second is waited
# for.
await() {
    _i=0
    while [ "$_i" -lt $((AWAIT_TIMEOUT * 4)) ]; do
        snap
        [ "$(grep -cF -e "$1" "$SEEN")" -ge "${2:-1}" ] && return
        _i=$((_i + 1))
        sleep 0.2
    done
    echo "$0: waited ${AWAIT_TIMEOUT}s for \"$1\" on the screen" >&2
}

# awaitprompt: until the batch file has run out and COMMAND.COM is asking
# again, which is the prompt at the end of the last line of the screen.  It
# is the end of it rather than the whole of it because a utility that writes
# its last message without a return -- CHKDSK's count of the lost chains it
# found -- leaves the prompt on the same line as the message.
awaitprompt() {
    _i=0
    while [ "$_i" -lt $((AWAIT_TIMEOUT * 4)) ]; do
        snap
        _last=$(grep -v '^$' "$SEEN" | tail -1)
        [ "${_last%A>}" != "$_last" ] && return
        _i=$((_i + 1))
        sleep 0.2
    done
    echo "$0: waited ${AWAIT_TIMEOUT}s for the prompt to come back" >&2
}

# awaitprint FILE TEXT [TIMES]: until TEXT is in what the guest has printed.
# What a test sends to PRN is not on the screen, and QEMU writes the parallel
# port through to the file as the guest writes it, so this is the wait for a
# question asked on a handle the batch file redirected.
awaitprint() {
    _i=0
    while [ "$_i" -lt $((AWAIT_TIMEOUT * 10)) ]; do
        [ -f "$1" ] && [ "$(grep -caF -e "$2" "$1")" -ge "${3:-1}" ] && return
        _i=$((_i + 1))
        sleep 0.1
    done
    echo "$0: waited ${AWAIT_TIMEOUT}s for \"$2\" from the printer" >&2
}
