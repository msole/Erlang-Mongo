%%==============================================================================
%% Copyright 2012 Erlang Solutions Ltd.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%==============================================================================
-module(adhoc_SUITE).
-compile(export_all).

-include_lib("escalus/include/escalus.hrl").
-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(NS_COMMANDS, <<"http://jabber.org/protocol/commands">>).

%%--------------------------------------------------------------------
%% Suite configuration
%%--------------------------------------------------------------------
all() ->
    [{group, disco_visible},
     {group, adhoc}].

groups() ->
    G = [{adhoc, [parallel], common_disco_cases() ++ hidden_disco_cases() ++ [ping]},
         {disco_visible, [parallel], common_disco_cases() ++ visible_disco_cases()}],
    ct_helper:repeat_all_until_all_ok(G).

common_disco_cases() ->
    [disco_info,
     disco_info_sm,
     disco_info_commands,
     disco_info_sm_commands,
     disco_info_ping,
     disco_items_commands].

hidden_disco_cases() ->
    [disco_items_hidden,
     disco_items_sm_hidden].

visible_disco_cases() ->
    [disco_items_visible,
     disco_items_sm_visible].

suite() ->
    escalus:suite().

init_per_suite(Config) ->
    escalus:init_per_suite(Config).

end_per_suite(Config) ->
    escalus_fresh:clean(),
    escalus:end_per_suite(Config).

init_per_group(GroupName, Config) ->
    Config1 = init_modules(GroupName, Config),
    escalus:create_users(Config1, escalus:get_users([alice, bob])).

end_per_group(GroupName, Config) ->
    restore_modules(GroupName, Config),
    escalus:delete_users(Config, escalus:get_users([alice, bob])).

init_per_testcase(CaseName, Config) ->
    escalus:init_per_testcase(CaseName, Config).

end_per_testcase(CaseName, Config) ->
    escalus:end_per_testcase(CaseName, Config).

init_modules(disco_visible, Config) ->
    Config1 = escalus:init_per_suite(dynamic_modules:save_modules(domain(), Config)),
    dynamic_modules:ensure_modules(domain(), [{mod_adhoc, [{report_commands_node, true}]}]),
    Config1;
init_modules(_, Config) ->
    Config.

restore_modules(disco_visible, Config) ->
    dynamic_modules:restore_modules(domain(), Config);
restore_modules(_, Config) ->
    ok.

%%--------------------------------------------------------------------
%% Adhoc tests
%%--------------------------------------------------------------------

disco_info(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                Server = escalus_client:server(Alice),
                escalus:send(Alice, escalus_stanza:disco_info(Server)),
                Stanza = escalus:wait_for_stanza(Alice),
                escalus:assert(has_feature, [?NS_COMMANDS], Stanza),
                escalus:assert(is_stanza_from, [domain()], Stanza)
        end).

disco_info_sm(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                AliceJid = escalus_client:short_jid(Alice),
                escalus:send(Alice, escalus_stanza:disco_info(AliceJid)),
                Stanza = escalus:wait_for_stanza(Alice),
                escalus:assert(has_feature, [?NS_COMMANDS], Stanza),
                escalus:assert(is_stanza_from, [AliceJid], Stanza)
        end).

disco_info_commands(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                Server = escalus_client:server(Alice),
                escalus:send(Alice, escalus_stanza:disco_info(Server, ?NS_COMMANDS)),
                Stanza = escalus:wait_for_stanza(Alice),
                escalus:assert(has_identity, [<<"automation">>, <<"command-list">>], Stanza),
                escalus:assert(is_stanza_from, [domain()], Stanza)
        end).

disco_info_sm_commands(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                AliceJid = escalus_client:short_jid(Alice),
                escalus:send(Alice, escalus_stanza:disco_info(AliceJid, ?NS_COMMANDS)),
                Stanza = escalus:wait_for_stanza(Alice),
                escalus:assert(has_identity, [<<"automation">>, <<"command-list">>], Stanza),
                escalus:assert(is_stanza_from, [AliceJid], Stanza)
        end).

disco_info_ping(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                Server = escalus_client:server(Alice),
                escalus:send(Alice, escalus_stanza:disco_info(Server, <<"ping">>)),
                Stanza = escalus:wait_for_stanza(Alice),
                escalus:assert(has_identity, [<<"automation">>, <<"command-node">>], Stanza),
                escalus:assert(has_feature, [?NS_COMMANDS], Stanza),
                escalus:assert(is_stanza_from, [domain()], Stanza)
        end).

disco_items_hidden(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                Server = escalus_client:server(Alice),
                escalus:send(Alice, escalus_stanza:disco_items(Server)),
                Stanza = escalus:wait_for_stanza(Alice),
                Query = exml_query:subelement(Stanza, <<"query">>),
                ?assertEqual(undefined,
                             exml_query:subelement_with_attr(Query, <<"node">>, ?NS_COMMANDS)),
                escalus:assert(is_stanza_from, [domain()], Stanza)
        end).

disco_items_sm_hidden(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                AliceJid = escalus_client:short_jid(Alice),
                escalus:send(Alice, escalus_stanza:disco_items(AliceJid)),
                Stanza = escalus:wait_for_stanza(Alice),
                Query = exml_query:subelement(Stanza, <<"query">>),
                ?assertEqual(undefined,
                             exml_query:subelement_with_attr(Query, <<"node">>, ?NS_COMMANDS)),
                escalus:assert(is_stanza_from, [AliceJid], Stanza)
        end).

disco_items_visible(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                Server = escalus_client:server(Alice),
                escalus:send(Alice, escalus_stanza:disco_items(Server)),
                Stanza = escalus:wait_for_stanza(Alice),
                Query = exml_query:subelement(Stanza, <<"query">>),
                Item = exml_query:subelement_with_attr(Query, <<"node">>, ?NS_COMMANDS),
                ?assertEqual(Server, exml_query:attr(Item, <<"jid">>)),
                escalus:assert(is_stanza_from, [domain()], Stanza)
        end).

disco_items_sm_visible(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                AliceJid = escalus_client:short_jid(Alice),
                escalus:send(Alice, escalus_stanza:disco_items(AliceJid)),
                Stanza = escalus:wait_for_stanza(Alice),
                Query = exml_query:subelement(Stanza, <<"query">>),
                Item = exml_query:subelement_with_attr(Query, <<"node">>, ?NS_COMMANDS),
                ?assertEqual(AliceJid, exml_query:attr(Item, <<"jid">>)),
                escalus:assert(is_stanza_from, [AliceJid], Stanza)
        end).

disco_items_commands(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                Server = escalus_client:server(Alice),
                escalus:send(Alice, escalus_stanza:disco_items(Server, ?NS_COMMANDS)),
                Stanza = escalus:wait_for_stanza(Alice),
                Query = exml_query:subelement(Stanza, <<"query">>),
                Item = exml_query:subelement_with_attr(Query, <<"node">>, <<"ping">>),
                ?assertEqual(Server, exml_query:attr(Item, <<"jid">>)),
                escalus:assert(is_stanza_from, [domain()], Stanza)
        end).

ping(Config) ->
    escalus:fresh_story(Config, [{alice, 1}],
        fun(Alice) ->
                %% Alice pings the server using adhoc command
                escalus_client:send(Alice, escalus_stanza:to(
                                             escalus_stanza:adhoc_request(<<"ping">>),
                                             domain())),
                %% Server replies to Alice with pong
                AdHocResp = escalus_client:wait_for_stanza(Alice),
                escalus:assert(is_adhoc_response, [<<"ping">>, <<"completed">>],
                               AdHocResp)
        end).

domain() ->
    ct:get_config({hosts, mim, domain}).
