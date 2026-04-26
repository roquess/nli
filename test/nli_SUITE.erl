-module(nli_SUITE).
-include_lib("common_test/include/ct.hrl").
-export([all/0, suite/0,
         load_missing_tokenizer/1,
         load_missing_model/1,
         score_entailment_higher_than_contradiction/1, score_range/1]).

suite() -> [{timetrap, {seconds, 30}}].

all() -> [load_missing_tokenizer, load_missing_model,
          score_entailment_higher_than_contradiction, score_range].

load_missing_tokenizer(_Config) ->
    {error, _} = nli:load("/nonexistent/tokenizer.json",
                           "/nonexistent/model.onnx").

load_missing_model(Config) ->
    DataDir = ?config(data_dir, Config),
    TokPath = filename:join(DataDir, "tokenizer.json"),
    {error, _} = nli:load(TokPath, "/nonexistent/model.onnx").

model_path(Config) ->
    DataDir = ?config(data_dir, Config),
    {filename:join(DataDir, "model/tokenizer.json"),
     filename:join(DataDir, "model/model.onnx")}.

score_entailment_higher_than_contradiction(Config) ->
    {TokPath, ModelPath} = model_path(Config),
    case filelib:is_regular(ModelPath) of
        false -> {skip, "NLI model not present"};
        true  ->
            {ok, N} = nli:load(TokPath, ModelPath),
            %% Clear entailment: "A man is eating food" -> "A person is eating"
            {ok, S1} = nli:score(N,
                <<"A man is eating food.">>,
                <<"A person is eating.">>),
            %% Clear contradiction: "A man is eating food" -> "No one is eating"
            {ok, S2} = nli:score(N,
                <<"A man is eating food.">>,
                <<"No one is eating.">>),
            nli:unload(N),
            true = S1 > S2
    end.

score_range(Config) ->
    {TokPath, ModelPath} = model_path(Config),
    case filelib:is_regular(ModelPath) of
        false -> {skip, "NLI model not present"};
        true  ->
            {ok, N}  = nli:load(TokPath, ModelPath),
            {ok, S}  = nli:score(N, <<"The sky is blue.">>, <<"It is daytime.">>),
            nli:unload(N),
            true = S >= 0.0,
            true = S =< 1.0
    end.
