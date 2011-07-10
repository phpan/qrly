-module(qrly_html).
-export([parse/1, parse_string/1, to_file/2, to_string/1, filter/2, test/0]).

-behaviour(qrly).

-include_lib("eunit/include/eunit.hrl").

-define(TEST_FILE, "../extra/test/test.html").

% external api

parse(FilePath) ->
    {Status, Content} = file:read_file(FilePath),

    if
        Status == ok ->
            Result = mochiweb_html:parse(Content);

        Status == error ->
            Result = Content
    end,

    {Status, Result}.

parse_string(Str) ->
    mochiweb_html:parse(Str).

to_file(Qrly, Path) ->
    Str = to_string(Qrly),

    case file:open(Path, [write]) of
        {ok, Device} ->
            file:write(Device, Str),
            {ok, Qrly};
        {error, _Reason} = Error ->
            Error
    end.

to_string(Qrly) ->
    mochiweb_html:to_html(Qrly).

filter(Qrly, Expression) -> {Qrly, Expression}.

% test helpers

filter_file(Expr) ->
    {ok, Content} = parse(?TEST_FILE),
    qrly:filter(Content, Expr).

test() ->
    eunit:test(?MODULE).

assertContent(Tag, ExpectedContent) ->
    {_, _, [Content]} = Tag,
    ?assertEqual(ExpectedContent, Content).

% tests

parse_existing_test() ->
    ok, _Content = parse(?TEST_FILE).

parse_inexisting_test() ->
    error, _Content = parse("extra/test/inexisting.html").

get_tag_test() ->
    Result = filter_file("h1"),
    ?assertEqual(3, length(Result)),
    [FirstTag, SecondTag, ThirdTag] = Result,
    assertContent(FirstTag, <<"personal">>),
    assertContent(SecondTag, <<"projects">>),
    assertContent(ThirdTag, <<"others">>).

get_by_class_test() ->
    Result = filter_file(".first-title"),
    ?assertEqual(1, length(Result)),
    [FirstTag] = Result,
    assertContent(FirstTag, <<"personal">>).

get_by_class_and_tag_test() ->
    Result = filter_file("h1.first-title"),
    ?assertEqual(1, length(Result)),
    [FirstTag] = Result,
    assertContent(FirstTag, <<"personal">>).

get_by_tag_and_attr_equal_test() ->
    Result = filter_file("a[href=\"http://www.emesene.org\"]"),
    ?assertEqual(1, length(Result)),
    [FirstTag] = Result,
    assertContent(FirstTag, <<"emesene">>).

