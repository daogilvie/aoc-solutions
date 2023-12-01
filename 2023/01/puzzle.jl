total = 0

function compute_line_value(line::String)::Int
    first = line[findfirst(r"\d", line)]
    rev = reverse(line)
    last = rev[findfirst(r"\d", rev)]
    parse(Int, "$first$last")
end

for line in eachline("./test.txt")
    global total += compute_line_value(line)
end

println("Part 1: $total")
total = 0

number_regex = r"(one|two|three|four|five|six|seven|eight|nine|\d)"
word_values = Dict("one" => "1", "two" => "2", "three" => "3", "four" => "4", "five" => "5", "six" => "6", "seven" => "7", "eight" => "8", "nine" => "9")

function compute_line_value_wordy(line::String)::Int
    matches = collect(eachmatch(number_regex, line, overlap=true))
    first_match = matches[1]
    last_match = matches[end]
    first = get(word_values, first_match.match, first_match.match)
    last = get(word_values, last_match.match, last_match.match)
    parse(Int, "$first$last")
end

for line in eachline("./input.txt")
    # We want to replace the first and last matches with their digits specifically
    value = compute_line_value_wordy(line)
    global total += value
end

println("Part 2: $total")
