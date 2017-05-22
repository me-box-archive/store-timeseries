open Core.Std

let cat = ref (Ezjsonm.from_channel (open_in "base-cat.json"))

let has_href_and_metadata item =
  let open Ezjsonm in
  (mem item ["href"]) && (mem item ["item-metadata"])

let is_rel_val_pair item =
  let open Ezjsonm in
  let metadata = find item ["item-metadata"] in
  let list = get_list ident metadata in
  List.for_all ~f:(fun x -> mem x ["rel"] && mem x ["val"]) list


let has_rel_term term item =
  let open Ezjsonm in
  let metadata = find item ["item-metadata"] in
  let string_exists string term =
    String.split string ~on:':'
    |> List.exists ~f:(fun x -> x = term) in 
  let get_string_exn = function
    | Some (x,y) -> get_string y
    | None -> raise (Invalid_argument "Option.get") in
  get_list get_dict metadata
  |> List.map ~f:(fun x -> get_string_exn (List.hd x))
  |> List.exists ~f:(fun x -> (string_exists x term))


let is_valid_item item =
  (has_href_and_metadata item) &&
  (is_rel_val_pair item) &&
  (has_rel_term "hasDescription" item) &&
  (has_rel_term "isContentType" item)
  
let update_cat item =
  if is_valid_item item then
    begin
      let open Ezjsonm in
      let current_items = find !cat ["items"] in
      let current_list = get_list ident current_items in
      let new_list = List.cons item current_list in
      let new_items = list ident new_list in
      cat := update !cat ["items"] (Some new_items);
      Ezjsonm.dict [("status", (`Bool true))]
    end
  else
    begin
      Ezjsonm.dict [("status", (`Bool false))]
    end


let get_cat () =
  `O (Ezjsonm.get_dict !cat)
