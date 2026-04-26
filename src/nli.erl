-module(nli).
-export([load/2, score/3, unload/1]).
-opaque nli() :: map().
-export_type([nli/0]).

-spec load(file:filename(), file:filename()) -> {ok, nli()} | {error, term()}.
load(_TokPath, _ModelPath) -> error(not_implemented).

-spec score(nli(), binary(), binary()) -> {ok, float()} | {error, term()}.
score(_NLI, _Premise, _Hypothesis) -> error(not_implemented).

-spec unload(nli()) -> ok.
unload(_NLI) -> ok.
