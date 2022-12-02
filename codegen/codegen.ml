open Syntax

let rec codegen (p: prog) : python list =
  header @ (codegen_stmts p.body)

and codegen_stmts (ss : stmt list) : python list =
  match ss with
  | s::xs -> (codegen_stmt s)::(`Print "")::(codegen_stmts xs)
  | [] -> []

and codegen_stmt (s : stmt) : python =
  match s with
  | MacroDecl md -> codegen_macrodecl md
  | TextDecl td -> codegen_textdecl td

and codegen_macrodecl md =
  let Id name = md.macro_id in
  let Str value = md.init in
  `Var (name,value)

and string_to_list str i =
  if i == String.length str then []
  else (String.get str i)::(string_to_list str (i+1))

and process_emoticon emo msg =
  match msg with
  | [] -> failwith "should not occur"
  | c::rem ->
    (if Char.equal c ']' then (rem,emo)
    else process_emoticon (emo ^ (String.make 1 c)) rem)

and process_macro emo msg =
  match msg with
  | [] -> failwith "should not occur"
  | c::rem ->
    (if Char.equal c ':' then (rem,emo)
    else process_macro (emo ^ (String.make 1 c)) rem)

and get_spam_count emo msg =
  match msg with
  | [] -> failwith "should not occur"
  | c::rem ->
    (if Char.equal c ' ' then (rem,emo)
    else process_macro (emo ^ (String.make 1 c)) rem)

and create_spam emo n =
  match n with
  | 0 -> ""
  | _ -> "{" ^ emo ^ "}" ^ (create_spam emo (n-1))

and process_spam msg =
  let (rem,num) = get_spam_count "" msg in
  let (rem',emo) = process_macro "" rem in
  (rem', create_spam emo (int_of_string (String.trim num)))

and process_string (msg : char list) : string =
  match msg with
  | [] -> ""
  | c::rem ->
    (if Char.equal c '[' then
     (let (rem',emojified) = process_emoticon "" rem in
      (emoticon emojified) ^ (process_string rem'))
     else if Char.equal c ':' then
      (let (rem',emojified) = process_macro "" rem in
       "{" ^ emojified ^ "}" ^ (process_string rem'))
     else if Char.equal c '#' then
      (let (rem',emojified) = process_spam rem in
      emojified ^ (process_string rem'))
     else (String.make 1 c) ^ (process_string rem))

and codegen_textdecl td =
  let Str str = td.words in
  let message = string_to_list str 0 in
  let output = process_string message in
  `Print output

and emoticon (e : string) : string =
  if e = ":)" then "🙂" else
  if e = ":D" then "😃" else
  if e = ":(" then "🙁" else
  if e = ":'(" then "😥" else
  if e = "<3" then "❤️ " else
  if e = ":P" then "😛" else
  if e = ";)" then "😉" else
  "💩"

and header : python list =
  [`Var ("angry","😡");
   `Var ("meditate","🧘‍♂️");
   `Var ("party","🎉");
   `Var ("eyes","👀");
   ]