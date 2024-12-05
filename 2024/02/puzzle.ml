let read_lines filename = 
  let content =
      In_channel.with_open_text
        filename
        In_channel.input_all in
  String.split_on_char '\n' content

let line_to_ints line =
  Array.of_list
    (List.filter_map int_of_string_opt 
      (String.split_on_char ' ' line))

let calc_diffs (reports : int array) = 
  let len = (Array.length reports - 1) in
  let firsts = Array.sub reports 0 len in
  let nexts = Array.sub reports 1 len in
  Array.map2 Int.sub firsts nexts 

let is_safe (diffs : int array) =
  let safe_asc = (Array.for_all (fun x -> x > 0) diffs) && (Array.for_all (fun x -> x < 4) diffs) in
  let safe_desc = (Array.for_all (fun x -> x < 0) diffs) && (Array.for_all (fun x -> x > -4) diffs) in
  safe_asc || safe_desc

let gen_skipped_report report index _ =
  let len = Array.length report in
  if index = 0 then
    Array.sub report 1 (len - 1)
  else if index == len - 1 then
    Array.sub report 0 (len - 1)
  else
    Array.append (Array.sub report 0 index) (Array.sub report (index + 1) (len - index - 1))

let generate_report_set report =
  Array.to_list (Array.mapi (gen_skipped_report report) report)

let is_safe_damped report =
  let report_set = generate_report_set report in
  let diffs = calc_diffs report in
  let diff_set = List.map calc_diffs report_set in
  is_safe diffs || List.exists is_safe diff_set

let attempt_p1 fname =
  let reports = List.map line_to_ints (read_lines fname) in
  let diffs = List.map calc_diffs reports in
  List.length (List.filter is_safe diffs)

let attempt_p2 fname =
  let reports = List.map line_to_ints (read_lines fname) in
  List.length (List.filter is_safe_damped reports)

let attempt = 
  begin
    let test_p1 = attempt_p1 "sample.txt" in
    if test_p1 != 2 then
      failwith (Format.sprintf "Expected 2, got %d\n" test_p1)
    else
      Format.printf "Part 1 = %d\n" (attempt_p1 "input.txt");

    let test_p2 = attempt_p2 "sample.txt" in
    if test_p2 != 4 then
      failwith (Format.sprintf "Expected 4, got %d\n" test_p2)
    else 
      Format.printf "Part 2 = %d\n" (attempt_p2 "input.txt")
  end

