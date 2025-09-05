#!/bin/zsh

# This Script use osascript [built-in command for macOS]

osascriptSpotify="osascript -e 'tell application \"Spotify\" to"

if [ $SPOTIFY_SCRIPT -eq 1 ]; then
    unalias splay 2>/dev/null
    unalias snext 2>/dev/null
    unalias sprev 2>/dev/null
    unalias scurrent 2>/dev/null
    export SPOTIFY_SCRIPT=0
    echo "unload script!"
else
    alias splay="${osascriptSpotify} playpause'"
    alias snext="${osascriptSpotify} next track'"
    alias sprev="${osascriptSpotify} previous track'"
    alias scurrent="${osascriptSpotify} name of current track & \" - \" & artist of current track'"
    export SPOTIFY_SCRIPT=1
    echo "load script!"
fi