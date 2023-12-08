struct Node
    left::Int16
    right::Int16
end

function solve_p1(filename)

    nodes::Array{Node,1} = []
    name_indexes::Array{AbstractString,1} = []

    file_io = open(filename, "r")
    turns = readline(file_io)
    readline(file_io)

    specs = collect(eachline(file_io))
    name_indexes = map(x -> x[1:3], specs)

    function make_node(spec)
        l_index = findfirst(x -> x == spec[8:10], name_indexes)
        r_index = findfirst(x -> x == spec[13:15], name_indexes)
        return Node(l_index, r_index)
    end

    nodes = map(make_node, specs)

    start_index = findfirst(x -> x == "AAA", name_indexes)
    end_index = findfirst(x -> x == "ZZZ", name_indexes)

    where_am_i = start_index
    steps_taken = 0
    for turn in Iterators.cycle(turns)
        if where_am_i == end_index
            break
        end
        n = nodes[where_am_i]
        where_am_i = turn == 'L' ? n.left : n.right
        steps_taken += 1
    end

    return steps_taken
end

function solve_p2(filename)

    nodes::Array{Node,1} = []
    name_indexes::Array{AbstractString,1} = []

    file_io = open(filename, "r")
    turns = readline(file_io)
    readline(file_io)

    specs = collect(eachline(file_io))
    name_indexes = map(x -> x[1:3], specs)

    function make_node(spec)
        l_index = findfirst(x -> x == spec[8:10], name_indexes)
        r_index = findfirst(x -> x == spec[13:15], name_indexes)
        return Node(l_index, r_index)
    end

    nodes = map(make_node, specs)

    start_indices = findall(x -> x[3] == 'A', name_indexes)
    end_indices = findall(x -> x[3] == 'Z', name_indexes)

    cycles = []

    for start in start_indices
        visited = zeros(Int, length(end_indices))
        where_am_i = start
        steps_taken = 0
        for turn in Iterators.cycle(turns)
            if where_am_i in end_indices
                lookup = findfirst(x -> x == where_am_i, end_indices)
                if visited[lookup] > 0
                    push!(cycles, steps_taken - visited[lookup])
                    break
                end
                visited[lookup] = steps_taken
            end
            n = nodes[where_am_i]
            where_am_i = turn == 'L' ? n.left : n.right
            steps_taken += 1
        end
    end

    return lcm(cycles...)
end


test_part_1 = solve_p1("./test.txt")
test_two_part_1 = solve_p1("./test_two.txt")

@assert(test_part_1 == 2, "Test Part 1 failed, got $test_part_1")
@assert(test_two_part_1 == 6, "Test Two Part 1 failed, got $test_two_part_1")

part_1 = solve_p1("./input.txt")
println("Part 1: $part_1")

test_part_2 = solve_p2("./test_three.txt")
@assert(test_part_2 == 6, "Test Part 2 failed, got $test_part_2")

part_2 = solve_p2("./input.txt")
println("Part 2: $part_2")
