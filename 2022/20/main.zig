const std = @import("std");
const utils = @import("aocutils");

const input = @embedFile("input.txt");
const example = @embedFile("test.txt");

const print = std.debug.print;

// Type shorthands
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const str = []const u8;

const Answer = utils.NumericAnswer(isize);

const ListEntry = struct { value: isize, next: ?*ListEntry, previous: ?*ListEntry, first: bool = false };

fn printList(list: ArrayList(ListEntry)) !void {
    const first: *ListEntry = for (list.items) |*e| {
        if (e.first) break e;
    } else return error.NoFirst;
    print("{d}", .{first.value});
    var current = first.next.?;
    while (current != first) {
        print(",{d}", .{current.value});
        current = current.next.?;
    }
    print("\n", .{});
}

pub fn solve(content: str, allocator: Allocator) !Answer {
    var lines = std.mem.tokenize(u8, content, "\n");
    const linecount = std.mem.count(u8, content, "\n") + 1;
    var values = ArrayList(ListEntry).initCapacity(allocator, linecount) catch unreachable;
    defer values.deinit();
    var i: usize = 0;
    var previous_entry: ?*ListEntry = null;
    while (lines.next()) |l| {
        const val = std.fmt.parseInt(isize, l, 10) catch unreachable;
        values.append(ListEntry{ .value = val, .previous = previous_entry, .next = null }) catch unreachable;
        if (previous_entry) |ptr_previous| {
            ptr_previous.*.next = &values.items[i];
        }
        previous_entry = &values.items[i];
        i += 1;
    }

    // Fix up the first and last entries
    values.items[0].first = true;
    values.items[0].previous = &values.items[i - 1];
    values.items[i - 1].next = &values.items[0];

    // try printList(values);

    for (values.items) |*entry| {
        if (entry.value > 0) {
            var target: *ListEntry = entry.next.?;
            var counter = entry.value;
            // Modify intial position
            entry.previous.?.next = target;
            target.previous = entry.previous;
            // Proceed along list
            while (counter > 0) : (counter -= 1) {
                if (entry.first) {
                    entry.first = false;
                    target.first = true;
                } else if (target.first) {
                    entry.first = true;
                    target.first = false;
                }
                target = target.next.?;
            }
            // Modify linked list pointers
            entry.next = target;
            entry.previous = target.previous;
            target.previous.?.next = entry;
            target.previous = entry;
        } else if (entry.value < 0) {
            var target: *ListEntry = entry.previous.?;
            var counter = entry.value;
            // Modify intial position
            entry.next.?.previous = target;
            target.next = entry.next;
            // Proceed along list
            while (counter < 0) : (counter += 1) {
                if (entry.first) {
                    entry.first = false;
                    target.first = true;
                } else if (target.first) {
                    entry.first = true;
                    target.first = false;
                }
                target = target.previous.?;
            }
            // Modify linked list pointers
            entry.previous = target;
            entry.next = target.next;
            target.next.?.previous = entry;
            target.next = entry;
        }
        // try printList(values);
    }
    // Find the index of the zero
    const zero_entry: *ListEntry = for (values.items) |*entry| {
        if (entry.value == 0) {
            break entry;
        }
    } else {
        return error.NoZero;
    };

    var sorted_from_zero = std.ArrayList(ListEntry).init(allocator);
    defer sorted_from_zero.deinit();

    sorted_from_zero.append(zero_entry.*) catch unreachable;

    var sorted_index: usize = 1;
    while (sorted_index < i) : (sorted_index += 1) {
        sorted_from_zero.append(sorted_from_zero.items[sorted_index - 1].next.?.*) catch unreachable;
    }

    const first_ind = @rem(1000, sorted_from_zero.items.len);
    const second_ind = @rem(2000, sorted_from_zero.items.len);
    const third_ind = @rem(3000, sorted_from_zero.items.len);

    var part_1: isize = sorted_from_zero.items[first_ind].value + sorted_from_zero.items[second_ind].value + sorted_from_zero.items[third_ind].value;

    var part_2: isize = 0;

    return Answer{ .part_1 = part_1, .part_2 = part_2 };
}

pub fn main() !void {
    utils.printHeader("Day 20");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }
    var answer = solve(input, allocator) catch unreachable;
    answer.print();
}

test "day 20 worked examples" {
    var answer = try solve(example, std.testing.allocator);
    var failed = false;
    std.testing.expect(answer.part_1 == 3) catch {
        print("{d} is not 3\n", .{answer.part_1});
        failed = true;
    };
    try std.testing.expect(!failed);
}
