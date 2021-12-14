open AbsLambdaQs
open AbsQSharp
open Printf

let unimplemented_error s = "Not yet implemented: " ^ s

let rec elab (prog : AbsQSharp.doc) : AbsLambdaQs.cmd =
  match prog with 
  | Prog ([ns]) -> elab_nmspace ns
  | _ -> failwith (unimplemented_error "Multiple namespaces")

and elab_nmspace (ns : AbsQSharp.nmspace) : AbsLambdaQs.cmd =
  match ns with
  (* TODO: do something with the namespace's name *)
  | NDec (_, elmts) -> elab_nselmts elmts

and elab_nselmts (elmts : AbsQSharp.nSElmnt list) : AbsLambdaQs.cmd =
  match elmts with
  (* TODO: shouldn't always return empty *)
  | [] -> CRet (ETriv)
  (* TODO: do something with imports *)
  | NSOp _ :: elmts -> elab_nselmts elmts
  | NSOpAs _ :: elmts -> elab_nselmts elmts
  | NSTy _ :: _ -> failwith (unimplemented_error "Type declarations (NSTy)")
  (* TODO: do something with declaration prefix; Ret is not the right construct here :)  *)
  | NSCall (_, calld) :: [] -> AbsLambdaQs.CRet (elab_calldec calld)
  | NSCall (_, calld) :: _ -> failwith (unimplemented_error "Multiple call declarations (NSCall)")

and elab_calldec (calld : AbsQSharp.callDec) : AbsLambdaQs.exp =
  match calld with
  | CDFun _ -> failwith (unimplemented_error "Function declarations (CDFun)")
  | CDOp (Ident name, TAEmpty, params, typ, CEmpty, body) ->
     (match params with
      | ParTpl ([ParNI (NItem (arg,typ))]) -> 
          AbsLambdaQs.proc (MVar (Ident name), elab_type typ, elab_body body)
      | _ -> failwith (unimplemented_error "Operations with multiple arguments"))
  | _ -> failwith (unimplemented_error "Operations with type parameters or characteristics (tyArg, chars)")

and elab_type (typ : AbsQSharp.typ) : AbsLambdaQs.typ =
  match typ with
  | TQbit -> AbsLambdaQs.TQbit (* TODO: should probably be TQref *)
  | TUnit -> AbsLambdaQs.TUnit
  | _ -> failwith (unimplemented_error "Most types (TEmp, TPar, TQNm, ...)")

and elab_body (body : AbsQSharp.body) : AbsLambdaQs.cmd =
  match body with
  | BSpec _ -> failwith (unimplemented_error "Specializations (BSpec)")
  | BScope (Scp stmts) -> elab_stmts stmts

and elab_stmts (stmts : AbsQSharp.stm list) : AbsLambdaQs.cmd =
  match stmts with
  (* TODO: shouldn't always return empty *)
  | [] -> CRet ETriv
  (* TODO: in general, we'll want to use CBnd -- what var should we bind to? *)
  | (SExp exp) :: [] -> AbsLambdaQs.CRet (elab_exp exp)
  | _ -> failwith (unimplemented_error "Most statements (SRet, SFail, SLet, ...)")

and elab_exp (exp : AbsQSharp.exp) : AbsLambdaQs.exp =
  match exp with
  | EName (QUnqual (Ident x)) -> EVar (MVar (Ident x))
  | ECall (e1, [e2]) -> AbsLambdaQs.EAp(elab_exp e1, elab_exp e2)
  | _ -> failwith (unimplemented_error "Most expressions")

(* Example: *)
let parse (c : in_channel) : AbsQSharp.doc =
    ParQSharp.pDoc LexQSharp.token (Lexing.from_channel c)

let elab_example () =
    let channel = open_in "qs-samples/TinyExample.qs" in
    let in_prog = parse channel in
    let out_prog = elab in_prog in
    print_string ("[Input abstract syntax]\n\n"^
                  (fun x -> ShowQSharp.show (ShowQSharp.showDoc x)) in_prog ^ "\n\n");
    print_string ("[Output abstract syntax]\n\n"^
                  (fun x -> ShowLambdaQs.show (ShowLambdaQs.showCmd x)) out_prog ^ "\n\n")
;;

elab_example ();;