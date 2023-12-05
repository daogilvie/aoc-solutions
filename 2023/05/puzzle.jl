"Mutate array by adding offset to each number if it falls between start (inclusive) and cutoff (not-inclusive)"
function mutate_entry(mutators, start)
    for m in mutators
        mutated = m(start)
        if mutated != start
            return mutated
        end
    end
    return start
end

function make_mutator(dest_start, source_start, steps)
    offset = dest_start - source_start
    cutoff = source_start + steps
    return function (x)
        if x < cutoff && x >= source_start
            return x + offset
        else
            return x
        end
    end
end

function make_mutator_from_def(mut_def)
    parts = map(x -> parse(Int, x), split(mut_def))
    return make_mutator(parts...)
end

function solve(filename)
    contents = open(filename, "r")
    seeds::AbstractArray{Int} = map(x -> parse(Int, x), split(chopprefix(readline(contents), "seeds: ")))

    while true
        map_def = lstrip(readuntil(contents, "\n\n"))
        if length(map_def) == 0
            break
        end
        parts = split(map_def, "\n", keepempty=false)

        mutators = map(make_mutator_from_def, parts[2:end])
        seeds = map(s -> mutate_entry(mutators, s), seeds)
    end

    return min(seeds...), 0
end

(test_part_1, test_part_2) = solve("./test.txt")
if test_part_1 == 35 && test_part_2 == 0
    (actual_part_1, actual_part_2) = solve("./input.txt")
    println("Part 1: $actual_part_1")
    println("Part 2: $actual_part_2")
else
    println("Test failed, got $test_part_1, $test_part_2 but expecting 35, 30")
end
