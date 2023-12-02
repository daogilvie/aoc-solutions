max_red = 12
max_green = 13
max_blue = 14
game_id_sum = 0;
for (game_id, details) in enumerate(eachline("./input.txt"))
    ball_sets = split(chopprefix(details, r"Game \d+: "), "; ")
    game_possible = true
    for balls in ball_sets
        for ball_count in split(balls, ", ")
            number, colour = split(ball_count)
            number = parse(Int, number)
            game_possible = game_possible &&
                            ((colour == "red" && number <= max_red) ||
                             (colour == "green" && number <= max_green) ||
                             (colour == "blue" && number <= max_blue))

        end
    end
    if game_possible
        global game_id_sum += game_id
    end
end

println("Part 1: $game_id_sum")

game_power_sum = 0

for (game_id, details) in enumerate(eachline("./input.txt"))
    max_seen = Dict("red" => 0, "green" => 0, "blue" => 0)
    ball_sets = split(chopprefix(details, r"Game \d+: "), "; ")
    game_possible = true
    for balls in ball_sets
        for ball_count in split(balls, ", ")
            number, colour = split(ball_count)
            number = parse(Int, number)
            max_seen[colour] = max(max_seen[colour], number)
        end
    end
    global game_power_sum += reduce(*, values(max_seen))
end

println("Part 2: $game_power_sum")
