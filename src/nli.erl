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

%% Return the probability that Premise entails Hypothesis. Range [0.0, 1.0].
%% Encodes the pair as: "Premise Hypothesis", runs ONNX inference.
%% The model output is a 3-class logit vector [contradiction, neutral, entailment].
-spec score(nli(), binary(), binary()) -> {ok, float()} | {error, term()}.
score(#{tok := Tok, session := Session}, Premise, Hypothesis) ->
    Text    = <<Premise/binary, " ", Hypothesis/binary>>,
    {IdsBin, MaskBin, TypeBin} = tok:encode(Tok, Text),
    MaxLen  = byte_size(IdsBin) div 4,
    Inputs  = build_inputs(Session, IdsBin, MaskBin, TypeBin, MaxLen),
    case onyx:run(Session, Inputs) of
        {error, _} = Err -> Err;
        {ok, Outputs}    ->
            case maps:values(Outputs) of
                []         -> {error, no_model_outputs};
                [Tensor|_] ->
                    Logits = onyx:to_list(Tensor),
                    {ok, entailment_prob(Logits)}
            end
    end.

%% Build input map filtered to only the names the model declares.
build_inputs(Session, IdsBin, MaskBin, TypeBin, MaxLen) ->
    InputNames = [Name || {Name, _, _} <- maps:get(inputs, Session)],
    DType      = input_dtype(Session),
    All = #{
        <<"input_ids">>      => make_tensor(IdsBin,  MaxLen, DType),
        <<"attention_mask">> => make_tensor(MaskBin, MaxLen, DType),
        <<"token_type_ids">> => make_tensor(TypeBin, MaxLen, DType)
    },
    maps:filter(fun(K, _) -> lists:member(K, InputNames) end, All).

%% tok always produces i32 bins; cast to the dtype the model expects if different.
make_tensor(I32Bin, MaxLen, i32) ->
    onyx:tensor(I32Bin, [1, MaxLen], i32);
make_tensor(I32Bin, MaxLen, DType) ->
    I64Bin = << <<V:64/signed-little>> || <<V:32/signed-little>> <= I32Bin >>,
    onyx:tensor(I64Bin, [1, MaxLen], DType).

%% Read dtype from the input_ids spec in the session.
input_dtype(Session) ->
    Inputs = maps:get(inputs, Session),
    case lists:keyfind(<<"input_ids">>, 1, Inputs) of
        {_, _, DType} -> DType;
        false         -> i64
    end.

%% Numerically stable softmax.
softmax(Logits) ->
    Max  = lists:max(Logits),
    Exps = [math:exp(X - Max) || X <- Logits],
    Sum  = lists:sum(Exps),
    [E / Sum || E <- Exps].

%% Extract entailment probability from 3-class logit output.
%% symanto/xlm-roberta-base-snli-mnli-anli-xnli label order: 0=entailment, 1=neutral, 2=contradiction.
entailment_prob(Logits) when length(Logits) >= 3 ->
    Probs = softmax(Logits),
    lists:nth(1, Probs);
entailment_prob(_) ->
    error(bad_logit_shape).
