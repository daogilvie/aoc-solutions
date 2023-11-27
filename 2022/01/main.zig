const std = @import("std");
const utils = @import("aocutils");

const Allocator = std.mem.Allocator;
const Answer = utils.Answer;

const input = @embedFile("input.txt");
const example = @embedFile("test.txt");

const descending = std.sort.desc(usize);

fn solve(contents: []const u8, allocator: Allocator) !Answer {
    var calorie_list = std.ArrayList(usize).init(allocator);
    defer calorie_list.deinit();

    var elf_chunks = std.mem.split(u8, contents, "\n\n");

    while (elf_chunks.next()) |elf_chunk| {
        var elf_items = std.mem.split(u8, elf_chunk, "\n");
        var total_calories: usize = 0;
        while (elf_items.next()) |calorie_bytes| {
            if (calorie_bytes.len == 0) continue; // Skip empty line at the end of the file
            const calorie_count = try std.fmt.parseInt(usize, calorie_bytes, 10);
            total_calories += calorie_count;
        }
        try calorie_list.append(total_calories);
    }

    const sorted = try calorie_list.toOwnedSlice();
    defer allocator.free(sorted);

    std.mem.sort(usize, sorted, {}, descending);

    return Answer{ .part_1 = sorted[0], .part_2 = sorted[0] + sorted[1] + sorted[2] };
}

pub fn run(allocator: Allocator) void {
    utils.printHeader("Day 1");
    const answer = solve(input, allocator) catch unreachable;
    answer.print();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }
    run(allocator);
}

test "day 1 worked example" {
    const solution = try solve(example, std.testing.allocator);
    try std.testing.expect(solution.part_1 == 24000);
    try std.testing.expect(solution.part_2 == 45000);
}
