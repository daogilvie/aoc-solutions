function do_puzzle_with_file(filename)
    lines = collect(eachline(filename))

    row_length = length(lines[1])

    value_matrix = ones(Int, length(lines), row_length)

    indices_to_check::Array{Tuple{Int64,Int64,Bool}} = []

    for (row_number, row) in enumerate(lines)
        col_number = 1
        while col_number < row_length
            if isdigit(row[col_number])
                number_string = join(Iterators.takewhile(isdigit, row[col_number:end]))
                number_val = parse(Int, number_string)
                last_col = col_number + length(number_string) - 1
                value_matrix[row_number, col_number:last_col] .= number_val
                col_number = last_col + 1
            else
                if row[col_number] != '.'
                    push!(indices_to_check, (row_number, col_number, row[col_number] == '*'))
                end
                col_number += 1
            end
        end
    end

    height = size(value_matrix, 1)
    width = size(value_matrix, 2)

    part_1_total = 0
    part_2_total = 0
    for (r, c, might_be_gear) in indices_to_check
        start_row = r > 1 ? r - 1 : r
        last_row = r < height ? r + 1 : r
        start_col = c > 1 ? c - 1 : c
        last_col = c < width ? c + 1 : c
        sub_matrix = value_matrix[start_row:last_row, start_col:last_col]
        unique_values = unique(sub_matrix)
        # Part 1 is just the sum of unique values, minus the 1 that will be there
        part_1_total += sum(unique_values) - 1
        # Part 2 is the product of unique values if there are 3 of them
        # Assuming no numbers double up around a single gear
        if might_be_gear && length(unique_values) == 3
            part_2_total += prod(unique_values)
        end
    end

    return (part_1_total, part_2_total)
end

(test_part_1, test_part_2) = do_puzzle_with_file("./test.txt")
if test_part_1 == 4361 && test_part_2 == 467835
    (actual_part_1, actual_part_2) = do_puzzle_with_file("./input.txt")
    println("Part 1: $actual_part_1")
    println("Part 2: $actual_part_2")
end
