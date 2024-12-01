let read_lines filename = 
  let content =
      In_channel.with_open_text
        filename
        In_channel.input_all in
  String.split_on_char '\n' content

let line_to_ints line =
    (List.filter_map int_of_string_opt 
      (String.split_on_char ' ' line))

let take_second lst = List.hd (List.tl lst)

let diff (f, s) = Int.abs(f - s)

let is_two_long lst = List.length lst == 2

let attempt_p1 fname =
  let rows = List.filter is_two_long (List.map line_to_ints (read_lines fname)) in
  let first = List.sort Int.compare (List.map List.hd rows) in
  let sec = List.sort Int.compare (List.map take_second rows) in
  let zipped = List.combine first sec in
  List.fold_left Int.add 0 (List.map diff zipped)

module IntMap = Map.Make(Int);;

let inc_if_some x = match x with
  | None -> Some 1
  | Some xv -> Some (xv + 1)

let add_to_counts counts elem = 
  IntMap.update elem inc_if_some counts

let mult_by_counts counts elem = 
  match IntMap.find_opt elem counts with
    | None -> 0
    | Some v -> elem * v

let pp_map ppf (m) =
  IntMap.iter (fun k v -> Format.fprintf ppf "%d -> %d@\n" k v) m

let attempt_p2 fname =
  let count_map: int IntMap.t = IntMap.empty in
  let rows = List.filter is_two_long (List.map line_to_ints (read_lines fname)) in
  let first = List.sort Int.compare (List.map List.hd rows) in
  let sec = List.sort Int.compare (List.map take_second rows) in
  let counts = List.fold_left add_to_counts count_map sec in
  let mults = List.map (mult_by_counts counts) first in
  List.fold_left Int.add 0 mults

let attempt = 
  begin
    let test_p1 = attempt_p1 "sample.txt" in
    if test_p1 != 11 then
      failwith (Format.sprintf "Expected 11, got %d\n" test_p1)
    else
      Format.printf "Part 1 = %d\n" (attempt_p1 "input.txt");

    let test_p2 = attempt_p2 "sample.txt" in
    if test_p2 != 31 then
      failwith (Format.sprintf "Expected 31, got %d\n" test_p2)
    else
      Format.printf "Part 2 = %d\n" (attempt_p2 "input.txt")
  end
