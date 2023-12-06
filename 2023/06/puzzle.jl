ACCEL_PER_SECOND = 1

function distance_for_charge_time(race_duration, charge_duration)
    time_travelling = race_duration - charge_duration
    speed = charge_duration * ACCEL_PER_SECOND
    return time_travelling * speed
end

function p1_solve(filename)
    (time_line, record_line) = collect(eachline(filename))
    race_durations = map(
        x -> parse(Int, x),
        split(chopprefix(time_line, "Time:"), keepempty=false))
    race_records = map(
        x -> parse(Int, x),
        split(chopprefix(record_line, "Distance:"), keepempty=false))

    winning_product = 1
    for (duration, record) in Iterators.zip(race_durations, race_records)
        winning_options = 0
        for charge = 1:duration
            distance = distance_for_charge_time(duration, charge)
            if distance > record
                winning_options += 1
            end
        end
        winning_product *= winning_options
    end
    return winning_product
end

function p2_solve(filename)
    (time_line, record_line) = collect(eachline(filename))

    duration = parse(Int, join(split(chopprefix(time_line, "Time:"), keepempty=false)))
    record = parse(Int, join(split(chopprefix(record_line, "Distance:"), keepempty=false)))

    winning_options = 0
    for charge = 1:duration
        distance = distance_for_charge_time(duration, charge)
        if distance > record
            winning_options += 1
        end
    end
    return winning_options
end

part_1 = p1_solve("./test.txt")
part_2 = p2_solve("./test.txt")
if part_1 == 288 && part_2 == 71503
    actual_part_1 = p1_solve("./input.txt")
    actual_part_2 = p2_solve("./input.txt")
    println("Part 1: $actual_part_1")
    println("Part 2: $actual_part_2")
else
    print("Test failed. Expecting 288, 71503, got $part_1, $part_2")
end
