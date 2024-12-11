type token = 
    | Integer of int
    | Plus
    | Minus
    | Eof;;

type lexer = { pos: int; expression: string; }

let get_ch lexer =
    let len = String.length lexer.expression in
    if len > lexer.pos
    then Some(String.get lexer.expression lexer.pos)
    else None;;

let is_whitespace ch = List.mem ch ['\r'; '\n'; ' ']

let advance lexer = 
    { pos= (lexer.pos + 1); expression= lexer.expression }

let read_until predicate lexer =
    let rec iter lxr acc = 
        match get_ch lxr with
        | None -> (lxr, acc)
        | Some ch ->
            if predicate ch
            then (lxr, acc)
            else iter (advance lexer) (1 + acc) 
    in

    let start = lexer.pos in
    let (new_lexer, limit) = iter lexer start in

    let sub = String.sub lexer.expression start limit in
    (sub, new_lexer)
;;



let rec next_token lexer =
    match get_ch lexer with
    | None -> Eof
    | Some(ch) ->
        match ch with
        | '+' -> Plus
        | '-' -> Minus
        | _ when is_whitespace ch -> 

            next_token (advance lexer)
        | _ -> 
            let (identifer, lexer) =  read_until is_whitespace lexer in
            match int_of_string_opt identifer with
            | None -> raise (Failure "boo")
            | Some i -> Integer i
;;

                    
                    

let new_lexer expr = { pos=0; expression=expr;};;

let lexer = new_lexer "1 + 1";;
match next_token lexer with
| Integer i -> print_int i
| _ -> print_string "sad life."
;;

