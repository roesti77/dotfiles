; Keys
(pair key: (key (unquoted_key)) @variable.member)
(pair key: (key (string)) @variable.member)

; Field names in table headers: hikes[3]{id,name,...}
(field_name (unquoted_key) @property)

; Header brackets and length: [3]
(header length: (number) @number)

; Values
(value (string) @string)
(value (unquoted_string) @string)
(value (number) @number)
(value (null) @constant.builtin)
(value (boolean) @boolean)

; Inline array values
(inline_values (value (unquoted_string) @string))
(inline_values (value (number) @number))
(inline_values (value (string) @string))

; Punctuation
":" @punctuation.delimiter
"," @punctuation.delimiter
"|" @punctuation.delimiter
"[" @punctuation.bracket
"]" @punctuation.bracket
"{" @punctuation.bracket
"}" @punctuation.bracket
