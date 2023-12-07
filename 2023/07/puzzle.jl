function card_index(c::AbstractChar)::Int8
    # Default is 'A'
    ind = 13
    if c == 'K'
        ind = 12
    elseif c == 'Q'
        ind = 11
    elseif c == 'J'
        ind = 10
    elseif c == 'T'
        ind = 9
    elseif c == '9'
        ind = 8
    elseif c == '8'
        ind = 7
    elseif c == '7'
        ind = 6
    elseif c == '6'
        ind = 5
    elseif c == '5'
        ind = 4
    elseif c == '4'
        ind = 3
    elseif c == '3'
        ind = 2
    elseif c == '2'
        ind = 1
    end
    return ind
end

function hand_type_score(hand::AbstractString)::Int8
    hnd_array::Array{Int8,1} = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    for c in hand
        hnd_array[card_index(c)] += 1
    end

    counts = sort(filter(x -> !iszero(x), hnd_array))
    distinct = length(counts)
    most = max(counts...)

    if most == 5
        # 5 of a kind
        return 7
    elseif most == 4
        # 4 of a kind
        return 6
    elseif most == 3
        if distinct == 2
            # Full house
            return 5
        else
            # Three of a kind
            return 4
        end
    elseif most == 2
        if distinct == 3
            # Two pair
            return 3
        else
            #One pair
            return 2
        end
    else
        # "high card"
        return 1
    end
    @assert(false, "Shouldn't get here")
end


function compare_hand_entries(left, right)
    if left[2] != right[2]
        return left[2] < right[2]
    else
        for (c_1, c_2) in zip(left[1], right[1])
            if c_1 == c_2
                continue
            else
                return card_index(c_1) < card_index(c_2)
            end
        end
    end

end

function preprocess(hand_and_bid)
    (hand, bid) = split(hand_and_bid)
    bid_n = parse(Int, bid)
    type_score = hand_type_score(hand)
    return (hand, type_score, bid_n)
end

function solve_p1(filename)

    hand_entries = map(preprocess, eachline(filename))
    sort!(hand_entries, lt=compare_hand_entries)

    winnings = 0
    for (rank, h_s) in enumerate(hand_entries)
        winnings += h_s[3] * rank
    end

    return winnings
end

test_part_1 = solve_p1("./test.txt")

@assert(test_part_1 == 6440, "Test Part 1 failed, got $test_part_1")
part_1 = solve_p1("./input.txt")
println("Part 1: $part_1")
