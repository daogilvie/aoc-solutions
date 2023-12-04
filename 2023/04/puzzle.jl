function solve(filename)
    part_1_total = 0
    lines = collect(eachline(filename))
    card_counts = ones(Int64, length(lines))
    for (card_number, line) in enumerate(lines)
        (_, w, r) = split(line, r"[|:]")
        winners = Set(split(w))
        revealed = Set(split(r))
        hits = intersect(winners, revealed)
        if !isempty(hits)
            count = length(hits)
            part_1_total += 2^(count - 1)
            card_counts[card_number+1:card_number+count] .+= card_counts[card_number]
        end
    end
    return part_1_total, sum(card_counts)
end

(test_part_1, test_part_2) = solve("./test.txt")
if test_part_1 == 13 && test_part_2 == 30
    (actual_part_1, actual_part_2) = solve("./input.txt")
    println("Part 1: $actual_part_1")
    println("Part 2: $actual_part_2")
else
    println("Test failed, got $test_part_1, $test_part_2 but expecting 13, 30")
end
