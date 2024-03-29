const std = @import("std");
const utils = @import("aocutils");

const input = @embedFile("input.txt");
const example = @embedFile("test.txt");

const str = []const u8;

const Allocator = std.mem.Allocator;
const Answer = utils.Answer;

const print = std.debug.print;

/// Classic anglophone-centric character-set maths.
fn toInd(char: u8) usize {
    return char - 97;
}

fn fromInd(ind: usize) u8 {
    return @truncate(ind + 97);
}

const PART_1_WINDOW_LENGTH: usize = 4;
const PART_2_WINDOW_LENGTH: usize = 14;

/// Return the number of u8s to advance to check the next window,
/// or 0 if this window is all different
fn checkWindowIsAllDifferent(window: []const u8) usize {
    var counts: [26]usize = .{0} ** 26;
    for (window) |char| {
        counts[toInd(char)] += 1;
    }
    return for (counts, 0..) |count, index| {
        if (count > 1) {
            const char = fromInd(index);
            break std.mem.indexOfScalar(u8, window, char).? + 1;
        }
    } else 0;
}

fn slideWindowToFindMarker(haystack: []const u8, window_size: usize) usize {
    var window_start: usize = 0;
    return while (window_start < haystack.len - window_size) {
        const window = haystack[window_start .. window_start + window_size];

        const diff: usize = checkWindowIsAllDifferent(window);
        if (diff > 0) {
            window_start += diff;
        } else break window_start + window_size;
    } else 0;
}

pub fn solve(contents: []const u8) !Answer {
    return Answer{ .part_1 = slideWindowToFindMarker(contents, PART_1_WINDOW_LENGTH), .part_2 = slideWindowToFindMarker(contents, PART_2_WINDOW_LENGTH) };
}

pub fn main() !void {
    utils.printHeader("Day 6");
    var answer = solve(input) catch unreachable;
    answer.print();
}

test "day 6 worked example" {
    const answer = try solve(example);
    std.testing.expect(answer.part_1 == 7) catch |err| {
        print("{d} is not 7\n", .{answer.part_1});
        return err;
    };
    std.testing.expect(answer.part_2 == 19) catch |err| {
        print("{d} is not 19\n", .{answer.part_2});
        return err;
    };
}
