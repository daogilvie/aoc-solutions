card_values = "23456789TJQKA"
card_values_joker_mode = "J23456789TQKA"

function hand_type_score(hand::AbstractString, joker_mode::Bool=false)::Int8
    hnd_array::Array{Int8,1} = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    values_string = joker_mode ? card_values_joker_mode : card_values
    for c in hand
        hnd_array[findfirst(c, values_string)] += 1
    end

    counts = sort(filter(x -> !iszero(x), hnd_array))
    sort!(counts, rev=true)
    distinct = length(counts)
    most = counts[1]

    @assert(length(counts) >= 1 && length(counts) <= 5)
    @assert(sum(hnd_array) == sum(counts))
    @assert(sum(counts) == 5)

    joker_count = hnd_array[1]
    if joker_mode && joker_count > 0
        # We always transform jokers to be another kind of card
        distinct -= 1
        # Jokers just always become more of whatever the most common card is
        # if they aren't themselves the most common card.
        if joker_count < most
            most += joker_count
        elseif joker_count < 5
            # there are more jokers than other cards, but it's not all jokers
            # they just add to whatever the next most common is
            most = joker_count + counts[2]
        end
    end

    # "high card"
    score = 1

    if most == 5
        # 5 of a kind
        score = 7
    elseif most == 4
        # 4 of a kind
        score = 6
    elseif most == 3
        if distinct == 2
            # Full house
            score = 5
        else
            # Three of a kind
            score = 4
        end
    elseif most == 2
        if distinct == 3
            # Two pair
            score = 3
        else
            #One pair
            score = 2
        end
    end

    # Return score and number of jokers
    return score
end


function make_comparator(joker_mode)
    values_string = joker_mode ? card_values_joker_mode : card_values
    return function compare_hand_entries(left, right)
        if left[2] != right[2]
            return left[2] < right[2]
        else
            for (c_1, c_2) in zip(left[1], right[1])
                if c_1 == c_2
                    continue
                else
                    return findfirst(c_1, values_string) < findfirst(c_2, values_string)
                end
            end
        end
    end
end

function preprocess(hand_and_bid, joker_mode::Bool=false)
    (hand, bid) = split(hand_and_bid)
    bid_n = parse(Int, bid)
    type_score = hand_type_score(hand, joker_mode)
    return (hand, type_score, bid_n)
end

function solve(filename, joker_mode)

    hand_entries = map(x -> preprocess(x, joker_mode), eachline(filename))
    sort!(hand_entries, lt=make_comparator(joker_mode))

    winnings = 0
    for (rank, h_s) in enumerate(hand_entries)
        winnings += h_s[3] * rank
    end

    return winnings
end

solve_p1(fn) = solve(fn, false)
solve_p2(fn) = solve(fn, true)

test_part_1 = solve_p1("./test.txt")
test_part_2 = solve_p2("./test.txt")

@assert(test_part_1 == 6440, "Test Part 1 failed, got $test_part_1")
@assert(test_part_2 == 5905, "Test Part 2 failed, got $test_part_2")
part_1 = solve_p1("./input.txt")
println("Part 1: $part_1")
part_2 = solve_p2("./input.txt")
println("Part 2: $part_2")
