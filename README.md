# nli

Pure Erlang Natural Language Inference scoring backed by a multilingual ONNX model.
Given a premise and a hypothesis, returns the probability that the premise *entails*
the hypothesis.

Wraps [tok](https://hex.pm/packages/tok) (tokenization) and
[onyx](https://hex.pm/packages/onyx) (ONNX inference). No Python at runtime.

## Installation

```erlang
%% rebar.config
{deps, [{nli, "0.1.0"}]}.
```

## Getting a model

```bash
pip install optimum
optimum-cli export onnx \
    --model MoritzLaurer/mDeBERTa-v3-base-mnli-xnli \
    ./model/
```

Any XNLI-compatible model with 3-class output (contradiction / neutral / entailment)
works. `nli` auto-detects the input dtype (`i32` vs `i64`) from the ONNX session.

## Quick start

```erlang
{ok, N}  = nli:load("path/to/tokenizer.json", "path/to/model.onnx"),

%% Entailment: high score
{ok, S1} = nli:score(N,
    <<"A man is eating food.">>,
    <<"A person is eating.">>),
%% S1 ~ 0.9

%% Contradiction: low score
{ok, S2} = nli:score(N,
    <<"A man is eating food.">>,
    <<"No one is eating.">>),
%% S2 ~ 0.02

nli:unload(N).
```

## API

```erlang
%% Load a tokenizer + ONNX NLI model.
-spec load(file:filename(), file:filename()) -> {ok, nli()} | {error, term()}.

%% Return the entailment probability for (Premise, Hypothesis). Range [0.0, 1.0].
-spec score(nli(), binary(), binary()) -> {ok, float()} | {error, term()}.

%% Release the ONNX session.
-spec unload(nli()) -> ok.
```

## Notes

- **Encoding**: the pair is encoded as `"Premise Hypothesis"` (space-concatenated).
  This works correctly for DeBERTa-family models which do not use `token_type_ids`.
- **Label order**: XNLI models output `[contradiction, neutral, entailment]`;
  `nli` returns `softmax(logits)[2]`.
- **Supported models**: any ONNX export of an XNLI-family multilingual NLI model
  (mDeBERTa, XLM-RoBERTa, etc.). fr/en/de/es/zh and more depending on the model.

## License

Apache 2.0 — see [LICENSE](LICENSE).
