Nonterminals root definition option fields field key_def value attribute_def attributes struct_fields struct_field struct_key_def atoms atom.
Terminals  table struct enum union namespace root_type include attribute file_identifier file_extension float int bool string string_constant '}' '{' '(' ')' '[' ']' ';' ',' ':' '='.
Rootsymbol root.

root -> definition      : {'$1', #{}}.
root -> option          : {#{}, add_opt('$1')}.
root -> root definition : add_def('$1', '$2').
root -> root option     : add_opt('$1', '$2').

% options (non-quoted)
option -> namespace string ';' : {get_name('$1'), get_value_atom('$2')}.
option -> root_type string ';' : {get_name('$1'), get_value_atom('$2')}.

% options (quoted)
option -> include string_constant ';'         : {get_name('$1'), get_value_bin('$2')}.
option -> attribute string_constant ';'       : {get_name('$1'), get_value_bin('$2')}.
option -> file_identifier string_constant ';' : {get_name('$1'), get_value_bin('$2')}.
option -> file_extension string_constant ';'  : {get_name('$1'), get_value_bin('$2')}.

% definitions
definition -> table string '{' fields '}'                             : #{get_value_atom('$2') => {table, '$4', []} }.
definition -> table string '{' '}'                                    : #{get_value_atom('$2') => {table, [], []} }.
definition -> table string '(' attributes ')' '{' fields '}'          : #{get_value_atom('$2') => {table, '$7', '$4'} }.
definition -> table string '(' attributes ')' '{' '}'                 : #{get_value_atom('$2') => {table, [], '$4'} }.
definition -> struct string '{' struct_fields '}'                     : #{get_value_atom('$2') => {struct, '$4', []} }.
definition -> struct string '(' attributes ')' '{' struct_fields '}'  : #{get_value_atom('$2') => {struct, '$7', '$4'} }.
definition -> enum string ':' string '{' atoms '}'                    : #{get_value_atom('$2') => {{enum, get_value_atom('$4')}, '$6', [] }}.
definition -> enum string ':' string '(' attributes ')' '{' atoms '}' : #{get_value_atom('$2') => {{enum, get_value_atom('$4')}, '$9', '$6' }}.
definition -> union string '{' atoms '}'                              : #{get_value_atom('$2') => {union, '$4', []} }.
definition -> union string '(' attributes ')' '{' atoms '}'           : #{get_value_atom('$2') => {union, '$7', '$4'} }.

% tables
fields -> field ';'         : [ '$1' ].
fields -> field ';' fields  : [ '$1' | '$3' ].

field -> key_def                    : {'$1', []}.
field -> key_def '(' attributes ')' : {'$1', '$3'}.

key_def -> string ':' string              : { get_value_atom('$1'), get_value_atom('$3') }.
key_def -> string ':' '[' string ']'      : { get_value_atom('$1'), {vector, get_value_atom('$4')}}.
key_def -> string ':' string '=' value    : { get_value_atom('$1'), {get_value_atom('$3'), '$5' }}.

attributes -> attributes ',' attribute_def   : [ '$3' | '$1' ].
attributes -> attribute_def                  : [ '$1' ].
attribute_def -> string ':' value            : { get_value_atom('$1'), '$3' }.
attribute_def -> string                      : get_value_atom('$1').

value -> int               : get_value('$1').
value -> float             : get_value('$1').
value -> bool              : get_value('$1').
value -> string_constant   : get_value_bin('$1').
value -> string            : get_value_bin('$1').

% structs
struct_fields -> struct_field ';'                : [ '$1' ].
struct_fields -> struct_field ';' struct_fields  : [ '$1' | '$3' ].

struct_field -> struct_key_def  : '$1'.

struct_key_def -> string ':' string              : { get_value_atom('$1'), get_value_atom('$3') }.

% enums + unions
atoms -> atom             : [ '$1' ].
atoms -> atom ',' atoms   : [ '$1' | '$3'].

atom -> string           : get_value_atom('$1').
atom -> string '=' value : { get_value_atom('$1'), '$3' }.

Erlang code.

get_value_atom({_Token, _Line, Value}) -> list_to_atom(Value).
get_value_bin({_Token, _Line, Value})  -> list_to_binary(Value).
get_value({_Token, _Line, Value})      -> Value.

get_name({Token, _Line, _Value})  -> Token;
get_name({Token, _Line})          -> Token.

add_def({Defs, Opts}, Def) -> {maps:merge(Defs, Def), Opts}.

init_opt() -> #{root_type => [], attributes => [], file_identifier => nil}.

add_opt({root_type, Value}) -> maps:merge(init_opt(), #{root_type => Value});
add_opt({file_identifier, Value}) -> maps:merge(init_opt(), #{file_identifier => Value});
add_opt({attribute, Value}) -> maps:merge(init_opt(), #{attributes => [Value]});
add_opt(_Opt)               -> init_opt().

add_opt({Defs, Opts}, {root_type, Value}) -> {Defs, maps:merge(Opts, #{root_type => Value})};
add_opt({Defs, Opts}, {file_identifier, Value}) -> {Defs, maps:merge(Opts, #{file_identifier => Value})};
add_opt({Defs, Opts}, {attribute, Value}) -> {Defs, get_and_update_opt(Opts, attributes, Value)};
add_opt(Root, _Opt)                       -> Root.

get_and_update_opt(Opts, Key, Value) ->
    ExistingValue = maps:get(Key, Opts),
    maps:put(Key, [Value | ExistingValue], Opts).
    
    