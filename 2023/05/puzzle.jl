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

module Lerps
using Base: product

"Simple representation of a linear interpolation range"
struct LerpDef
    domain_start::Int64
    domain_end::Int64
    range_start::Int64
    range_end::Int64
    size::Int64
end

function show_lerp(io::IO, l::LerpDef)
    show(io, l.domain_start)
    print(io, ",")
    show(io, l.domain_end)
    print(io, " -> ")
    show(io, l.range_start)
    print(io, ",")
    show(io, l.range_end)
    print(io, " ($(l.size))")

end

Base.show(io::IO, l::LerpDef) = show_lerp(io, l)
Base.print(io::IO, l::LerpDef) = show_lerp(io, l)

"Transform a single lerpdef into a set of contiguous lerp defs that cover the same domain but use ranges from the given set"
function extrude(original::LerpDef, subsequent_lerps::AbstractArray{LerpDef})::AbstractArray{LerpDef}
    new_lerps::AbstractArray{LerpDef} = []

    ascending_lerps = sort(subsequent_lerps, by=l -> l.domain_start)

    lerps_to_check = [original]
    last_checked::LerpDef = original
    while !isempty(lerps_to_check)
        checking = pop!(lerps_to_check)
        last_checked = checking
        for next in ascending_lerps
            # No overlap, no need to check any others
            if checking.range_end < next.domain_start
                # If we haven't moved off the original, don't do anything because that will happen automatically,
                # but if we have moved then we need to produce our final lerp
                if checking.size != original.size
                    push!(new_lerps, checking)
                end
                break
            end

            if checking.range_start < next.domain_start
                if checking.range_end <= next.domain_end
                    # Find portion of the original that remains unchanged and add it to the lerp list
                    front_overhang = next.domain_start - checking.range_start
                    remainder_lerp = LerpDef(
                        checking.domain_start,
                        checking.domain_start + front_overhang - 1,
                        checking.range_start,
                        checking.range_start + front_overhang - 1,
                        front_overhang)
                    overlap_lerp = LerpDef(
                        remainder_lerp.domain_end + 1,
                        checking.domain_end,
                        next.range_start,
                        next.range_start + checking.size - front_overhang - 1,
                        checking.size - front_overhang)
                    push!(new_lerps, remainder_lerp, overlap_lerp)

                    break
                else
                    # Make the front overhang, and rear overhang lerps
                    # The front one and overlap can get put straight in new_lerps because if
                    # it had hit any earlier range we'd already have lost it
                    # The rear one needs to be added to the check set
                    front_overhang = next.domain_start - checking.range_start
                    remainder_lerp = LerpDef(
                        checking.domain_start,
                        checking.domain_start + front_overhang - 1,
                        checking.range_start,
                        checking.range_start + front_overhang - 1,
                        front_overhang)
                    overlap_lerp = LerpDef(
                        remainder_lerp.domain_end + 1,
                        remainder_lerp.domain_end + next.size,
                        next.range_start,
                        next.range_end,
                        next.size)
                    overshoot_lerp = LerpDef(
                        overlap_lerp.domain_end + 1,
                        checking.domain_end,
                        checking.range_start + overlap_lerp.size + remainder_lerp.size,
                        checking.range_end,
                        checking.size - overlap_lerp.size - remainder_lerp.size)
                    push!(new_lerps, remainder_lerp, overlap_lerp)
                    push!(lerps_to_check, overshoot_lerp)
                    break
                end
            end # checking.range_start < next.domain_start

            if checking.range_end <= next.domain_end
                # Very simple case, just needs the transitive wiring done
                inner_offset = checking.range_start - next.domain_start
                l = LerpDef(
                    checking.domain_start,
                    checking.domain_end,
                    next.range_start + inner_offset,
                    next.range_start + inner_offset + checking.size - 1,
                    checking.size)
                push!(new_lerps, l)
                # We are now done, because no further intersection is possible
                break
            elseif checking.range_start <= next.domain_end
                overlap_size = (next.domain_end - checking.range_start) + 1
                overlap_lerp = LerpDef(
                    checking.domain_start,
                    checking.domain_start + overlap_size - 1,
                    next.range_end - overlap_size + 1,
                    next.range_end,
                    overlap_size)
                push!(new_lerps, overlap_lerp)
                overhang_lerp = LerpDef(
                    overlap_lerp.domain_end + 1,
                    checking.domain_end,
                    checking.range_start + overlap_size,
                    checking.range_end,
                    checking.size - overlap_size)
                push!(lerps_to_check, overhang_lerp)
                break
            end
        end
        last_checked = checking
    end

    # If new lerps is empty, that means no overlaps occurred at all
    if isempty(new_lerps)
        push!(new_lerps, original)
        # If the domain end doesn't match up, we probably have an overshoot needing cleanup
    elseif new_lerps[end].domain_end != original.domain_end
        push!(new_lerps, last_checked)
    end



    # INVARIANT: The domain of the input should be totally covered by all lerps in the output
    # sort!(new_lerps, by=x -> x.domain_start)
    # domain_check = new_lerps[1].domain_start - 1
    # total_size = 0
    # @assert(domain_check == original.domain_start - 1, "ERROR INCORRECT DOMAIN START $original | $new_lerps")
    # for (i, l) in enumerate(new_lerps)
    #     @assert(domain_check == l.domain_start - 1, "ERROR NON CONTIGUOUS DOMAIN, $i: $new_lerps")
    #     domain_check = l.domain_end
    #     total_size += l.size
    #     @assert(l.domain_end - l.domain_start == l.range_end - l.range_start, "NOT A BIJECTION NO MORE: $l")
    #     @assert(l.domain_end - l.domain_start == l.size - 1, "SIZE AND DOMAIN/RANGE SIZE DO NOT AGREE")
    # end
    # @assert(new_lerps[end].domain_end == original.domain_end, "ERROR INCORRECT DOMAIN END $original | $new_lerps")
    # @assert(total_size == original.size, "ERROR SIZE MISMATCH, EXPECT $(original.size), GOT $total_size")


    return new_lerps
end

function make_lerp(def)
    # Dest start, source start, steps
    parts = map(x -> parse(Int, x), split(def))
    return LerpDef(parts[2], parts[2] + parts[3] - 1, parts[1], parts[1] + parts[3] - 1, parts[3])
end


end

function galaxy_brain_solve(filename)
    contents = open(filename, "r")
    seeds::AbstractArray{Int} = map(x -> parse(Int, x), split(chopprefix(readline(contents), "seeds: ")))

    lerp_sets = []
    while true
        map_def = lstrip(readuntil(contents, "\n\n"))
        if length(map_def) == 0
            break
        end
        parts = split(map_def, "\n", keepempty=false)
        next_lerps = map(Lerps.make_lerp, parts[2:end])
        push!(lerp_sets, next_lerps)
    end

    current_minimum = 2^62
    for (seed_domain_start, seed_domain_size) in Iterators.partition(seeds, 2)
        seed_lerp = Lerps.LerpDef(seed_domain_start, seed_domain_start + seed_domain_size - 1, seed_domain_start, seed_domain_start + seed_domain_size - 1, seed_domain_size)
        current_lerps = [seed_lerp]
        for next_lerps in lerp_sets
            new_current_lerps = []
            for input_lerp in current_lerps
                append!(new_current_lerps, Lerps.extrude(input_lerp, next_lerps))
            end
            current_lerps = new_current_lerps
        end
        # PRO-TIP: If you assume an array is sorted, you should make sure it is
        # sorted because otherwise your life partner questions whether you should
        # maybe get hobbies that don't involve crying tears of frustration into
        # a keyboard
        sort!(current_lerps, by=x -> x.range_start)
        current_minimum = min(current_minimum, current_lerps[1].range_start)
    end

    return current_minimum
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

    return min(seeds...)
end

test_part_1 = solve("./test.txt")
test_part_2 = galaxy_brain_solve("./test.txt")
if test_part_1 == 35 && test_part_2 == 46
    actual_part_1 = solve("./input.txt")
    @time("Runtime for part 2 solution", actual_part_2 = galaxy_brain_solve("./input.txt"))
    println("Part 1: $actual_part_1")
    println("Part 2: $actual_part_2 (should be 41222968)")
else
    println("Test failed, got $test_part_1, $test_part_2 but expecting 35, 46")
end
