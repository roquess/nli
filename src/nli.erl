-module(nli).
-export([load/2, score/3, unload/1]).
-opaque nli() :: map().
-export_type([nli/0]).

%% Load a tok tokenizer and an ONNX NLI model.
-spec load(file:filename(), file:filename()) -> {ok, nli()} | {error, term()}.
load(TokPath, ModelPath) ->
    case tok:load(TokPath) of
        {error, _} = Err -> Err;
        {ok, Tok}        ->
            case onyx:load(ModelPath) of
                {error, _} = Err -> Err;
                {ok, Session}    ->
                    {ok, #{tok => Tok, session => Session}}
            end
    end.

%% Release the ONNX session.
-spec unload(nli()) -> ok.
unload(#{session := Session}) ->
    onyx:unload(Session).

-spec score(nli(), binary(), binary()) -> {ok, float()} | {error, term()}.
score(_NLI, _Premise, _Hypothesis) -> error(not_implemented).
