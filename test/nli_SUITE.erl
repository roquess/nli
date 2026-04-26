-module(nli_SUITE).
-include_lib("common_test/include/ct.hrl").
-export([all/0, suite/0,
         load_missing_tokenizer/1,
         load_missing_model/1]).

suite() -> [{timetrap, {seconds, 30}}].

all() -> [load_missing_tokenizer, load_missing_model].

load_missing_tokenizer(_Config) ->
    {error, _} = nli:load("/nonexistent/tokenizer.json",
                           "/nonexistent/model.onnx").

load_missing_model(Config) ->
    DataDir = ?config(data_dir, Config),
    TokPath = filename:join(DataDir, "tokenizer.json"),
    {error, _} = nli:load(TokPath, "/nonexistent/model.onnx").
