-module(glowup_ffi).
-export([exit/1]).

exit(N) ->
    halt(N).
