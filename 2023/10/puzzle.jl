UNVISITED = -1
LH = -2
RH = -3

UP = CartesianIndex(-1, 0)
DOWN = CartesianIndex(1, 0)
LEFT = CartesianIndex(0, -1)
RIGHT = CartesianIndex(0, 1)

UNIT = oneunit(CartesianIndex(1, 1))

function orthogonal(ind::CartesianIndex, width, height)
    neighbours = collect((ind-UNIT):(ind+UNIT))
    orths = filter(x -> x[1] == ind[1] || x[2] == ind[2], neighbours)
    return filter(x -> is_in_grid(x, width, height), orths)
end

function mark_if_appropriate(index, grid, mark)
    (height, width) = size(grid)
    if is_in_grid(index, width, height) && grid[index] < 0
        grid[index] = mark
        return true
    end
    return false
end

function calculate_facings(step)
    lh_facing = LEFT
    rh_facing = RIGHT
    if step == RIGHT
        lh_facing = UP
        rh_facing = DOWN
    elseif step == DOWN
        lh_facing = RIGHT
        rh_facing = LEFT
    elseif step == LEFT
        lh_facing = DOWN
        rh_facing = UP
    end

    return lh_facing, rh_facing
end

function find_next_march(previous, current, grid)
    symbol = grid[current]
    step = current - previous
    if symbol == '-' || symbol == '|'
        return step
    elseif symbol == 'J'
        if step[1] == 0
            return UP
        else
            return LEFT
        end
    elseif symbol == 'L'
        if step[1] == 0
            return UP
        else
            return RIGHT
        end
    elseif symbol == '7'
        if step[1] == 0
            return DOWN
        else
            return LEFT
        end
    elseif symbol == 'F'
        if step[1] == 0
            return DOWN
        else
            return RIGHT
        end
    end
end

function is_in_grid(index::CartesianIndex, width, height)
    return 1 <= index[1] <= height && 1 <= index[2] <= width
end


function flood_expand(value, grid)
    boundaries = findall(v -> v == value, grid)
    (height, width) = size(grid)

    while !isempty(boundaries)
        looking_at = pop!(boundaries)
        neighbours = orthogonal(looking_at, width, height)
        for n in neighbours
            if grid[n] == UNVISITED
                grid[n] = value
                push!(boundaries, n)
            end
        end
    end
end


function solve(filename)
    lines = collect(eachline(filename))

    height = length(lines)
    width = length(lines[1])

    grid = fill('.', height, width)
    distances = fill(UNVISITED, height, width)

    for (i, line) in enumerate(lines)
        grid[i, :] = collect(line)
    end

    start = findfirst(x -> x == 'S', grid)
    march_from = start

    distances[start] = 0

    # Check starting pipe options
    # Only need to check 3 of them because guaranteed to find at
    # least one pipe, and the march algorithm doesn't care which
    # direction it marches
    left = start + LEFT
    right = start + RIGHT
    above = start + UP
    if left[2] > 0 && grid[left] in ('F', '-', 'L')
        march_on = left
    elseif right[2] <= width && grid[right] in ('7', '-', 'J')
        march_on = right
    elseif above[1] > 0 && grid[above] in ('7', '|', 'F')
        march_on = above
    end

    step = march_on - march_from

    (lhf, rhf) = calculate_facings(step)

    taken = 1
    while march_on != start
        old_step = step
        step = find_next_march(march_from, march_on, grid)
        distances[march_on] = taken

        # Mark LHS/RHS based on _incoming_ step
        on_left = march_on + lhf
        on_right = march_on + rhf
        mark_if_appropriate(on_left, distances, LH)
        mark_if_appropriate(on_right, distances, RH)

        (lhf, rhf) = calculate_facings(step)
        # We've changed direction on this pipe, so need to mark additional LHS/RHS
        if step != old_step
            on_left = march_on + lhf
            on_right = march_on + rhf
            mark_if_appropriate(on_left, distances, LH)
            mark_if_appropriate(on_right, distances, RH)
        end
        march_from = march_on
        march_on = march_on + step
        taken += 1
    end

    # Now we flood fill our LH and RH values into any non-loop
    # spaces they are in
    flood_expand(LH, distances)
    flood_expand(RH, distances)

    lhs_count = count(x -> x == LH, distances)
    rhs_count = count(x -> x == RH, distances)

    # Assume that whichever flood fill is less prevalent is the "contained"
    # one, because that just seems more likely ¯\_(ツ)_/¯
    return floor(Int, taken / 2), min(lhs_count, rhs_count)

end

solve_p1(fn) = solve(fn)[1]
solve_p2(fn) = solve(fn)[2]

test_simple_one = solve_p1("./test_simple_loop.txt")
@assert(test_simple_one == 4, "$test_simple_one :(")
test_simple_longer = solve_p1("./test_simple_longer_loop.txt")
@assert(test_simple_longer == 8, "$test_simple_longer :(")
test_full_field = solve_p1("./test_full.txt")
@assert(test_full_field == 8, "$test_full_field :(")

test_enclosed_simple = solve_p2("./test_part_2.txt")
@assert(test_enclosed_simple == 4, "$test_enclosed_simple :(")
test_enclosed_big = solve_p2("./test_part_2_bigger.txt")
@assert(test_enclosed_big == 8, "$test_enclosed_big :(")
test_enclosed_full = solve_p2("./test_part_2_full.txt")
@assert(test_enclosed_full == 10, "$test_enclosed_full :(")

@time part_1, part_2 = solve("./input.txt")
@assert(part_1 == 6773, "BROKE PART 1: $part_1")
@assert(part_2 == 493, "BROKE PART 2: $part_2")
println("Part 1: $part_1")
println("Part 2: $part_2")
