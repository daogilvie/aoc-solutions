function solve(filename, backwards)
    terminal_sum = 0
    for line in eachline(filename)
        original::Vector{Int} = map(x -> parse(Int, x), split(line))
        if backwards
            sequence = reverse(original)
        else
            sequence = copy(original)
        end
        terminals::Vector{Int} = []
        bottom_diff::Int = 0
        while true
            push!(terminals, sequence[end])
            diffs::Vector{Int} = Vector{Int}(undef, length(sequence) - 1)
            for (i, val) in enumerate(sequence[2:end])
                diffs[i] = val - sequence[i]
            end
            if allequal(diffs)
                bottom_diff = diffs[1]
                break
            else
                sequence = diffs
            end
        end
        final_value = reduce(+, reverse(terminals); init=bottom_diff)
        terminal_sum += final_value
    end
    return terminal_sum
end

solve_p1(filename) = solve(filename, false)
solve_p2(filename) = solve(filename, true)

test_part_1 = solve_p1("./test.txt")
test_part_2 = solve_p2("./test.txt")

@assert(test_part_1 == 114, "Expected P1 == 114, got $test_part_1")
@assert(test_part_2 == 2, "Expected P2 == 2, got $test_part_2")

part_1 = solve_p1("./input.txt")
part_2 = solve_p2("./input.txt")

println("Part 1: $part_1")
println("Part 2: $part_2")
