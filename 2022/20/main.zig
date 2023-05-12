const std = @import("std");
const utils = @import("aocutils");

const input = @embedFile("input.txt");
const example = @embedFile("test.txt");

const print = std.debug.print;

const MAGICAL_DECRYPTION_CONSTANT: isize = 811589153;

// Type shorthands
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const str = []const u8;

const Answer = utils.NumericAnswer(isize);

const ListEntry = struct { value: isize, shift_value: isize, next: ?*ListEntry, previous: ?*ListEntry, first: bool = false };

fn printListInLinkOrder(list: *const ArrayList(ListEntry)) !void {
    const first: *ListEntry = for (list.items) |*e| {
        if (e.first) break e;
    } else return error.NoFirst;
    print("{d}({d} - {})", .{ first.value, first.shift_value, first.first });
    var current = first.next.?;
    while (current != first) {
        print(",{d}({d} - {})", .{ current.value, current.shift_value, current.first });
        current = current.next.?;
    }
    print("\n", .{});
}

fn printListInStoredOrder(list: *const ArrayList(ListEntry)) !void {
    print("{d}({d})", .{ list.items[0].value, list.items[0].shift_value });
    for (list.items[1..]) |current| {
        print(",{d}({d})", .{ current.value, current.shift_value });
    }
    print("\n", .{});
}

fn fillList(content: str, list: *ArrayList(ListEntry), value_multiplier: isize, apply_modulo: bool) usize {
    list.clearRetainingCapacity();
    var lines = std.mem.tokenize(u8, content, "\n");
    var previous_entry: ?*ListEntry = null;
    var i: usize = 0;
    while (lines.next()) |l| {
        const val = std.fmt.parseInt(isize, l, 10) catch unreachable;
        // Set shift value to the same as value for now — we loop through later to modulo it
        list.append(ListEntry{ .value = val * value_multiplier, .shift_value = val * value_multiplier, .previous = previous_entry, .next = null }) catch unreachable;
        if (previous_entry) |ptr_previous| {
            ptr_previous.*.next = &list.items[i];
        }
        previous_entry = &list.items[i];
        i += 1;
    }
    // Fix up the first and last entries
    list.items[0].first = true;
    list.items[0].previous = &list.items[i - 1];
    list.items[i - 1].next = &list.items[0];
    // Perform the modulo
    if (value_multiplier != 1 and apply_modulo) {
        const denominator = @intCast(isize, i) - 1;
        for (list.items) |*entry| {
            entry.shift_value = @mod(entry.shift_value, denominator);
        }
    }
    return i;
}

fn mix(values: *ArrayList(ListEntry)) !void {
    for (values.items) |*entry| {
        if (entry.shift_value > 0) {
            var target: *ListEntry = entry.next.?;
            var counter = entry.shift_value;
            // Modify intial position
            entry.previous.?.next = target;
            target.previous = entry.previous;
            // Proceed along list
            while (counter > 0) : (counter -= 1) {
                // Any time we are first and going to move, this can only happen
                // if we _start_ as first and move forward. Just make the next
                // entry first, job done.
                if (entry.first) {
                    entry.first = false;
                    target.first = true;
                }
                target = target.next.?;
            }
            // Modify linked list pointers
            entry.next = target;
            entry.previous = target.previous;
            target.previous.?.next = entry;
            target.previous = entry;
        } else if (entry.shift_value < 0) {
            var target: *ListEntry = entry.previous.?;
            // We use prev_target to track who we moved from behind,
            // so we can promote them to first if needed.
            var prev_target: *ListEntry = entry.next.?;
            var counter = entry.shift_value;
            // Modify intial position
            entry.next.?.previous = target;
            target.next = entry.next;
            // Proceed along list
            while (counter < 0) : (counter += 1) {
                // Moving backwards, we can _become_ first,
                if (entry.first) {
                    entry.first = false;
                    prev_target.first = true;
                } else if (target.first) {
                    entry.first = true;
                    target.first = false;
                }
                prev_target = target;
                target = target.previous.?;
            }
            // Modify linked list pointers
            entry.previous = target;
            entry.next = target.next;
            target.next.?.previous = entry;
            target.next = entry;
        }
    }
}

pub fn solve(content: str, allocator: Allocator) !Answer {
    const linecount = std.mem.count(u8, content, "\n") + 1;
    var values = ArrayList(ListEntry).initCapacity(allocator, linecount) catch unreachable;
    defer values.deinit();

    const list_length = fillList(content, &values, 1, false);

    const first_ind = @mod(1000, list_length);
    const second_ind = @mod(2000, list_length);
    const third_ind = @mod(3000, list_length);

    try mix(&values);

    var sorted_from_zero = std.ArrayList(ListEntry).init(allocator);
    defer sorted_from_zero.deinit();

    // Find the index of the zero
    var zero_entry: *ListEntry = for (values.items) |*entry| {
        if (entry.value == 0) {
            break entry;
        }
    } else {
        return error.NoZero;
    };

    sorted_from_zero.append(zero_entry.*) catch unreachable;

    var sorted_index: usize = 1;
    while (sorted_index < list_length) : (sorted_index += 1) {
        sorted_from_zero.append(sorted_from_zero.items[sorted_index - 1].next.?.*) catch unreachable;
    }

    const part_1: isize = sorted_from_zero.items[first_ind].value + sorted_from_zero.items[second_ind].value + sorted_from_zero.items[third_ind].value;

    // Reset input
    // Actually using the MAGICAL_DECRYPTION_CONSTANT would make the shifting too ardous.
    // We only really care about the modulus of it - 1, which is what would affect where the positions
    // change. We do this calculation inside fillList.
    // It's N-1 and not N because we only ever hop over other items, i.e hopping
    // forward off the end of the list does not put you into first place, it puts
    // you into second place
    _ = fillList(content, &values, MAGICAL_DECRYPTION_CONSTANT, true);

    inline for (0..10) |_| {
        try mix(&values);
    }

    // Find the index of the zero
    zero_entry = for (values.items) |*entry| {
        if (entry.value == 0) {
            break entry;
        }
    } else {
        return error.NoZero;
    };

    sorted_from_zero.clearRetainingCapacity();

    sorted_from_zero.append(zero_entry.*) catch unreachable;

    sorted_index = 1;
    while (sorted_index < list_length) : (sorted_index += 1) {
        sorted_from_zero.append(sorted_from_zero.items[sorted_index - 1].next.?.*) catch unreachable;
    }

    var part_2: isize = sorted_from_zero.items[first_ind].value + sorted_from_zero.items[second_ind].value + sorted_from_zero.items[third_ind].value;

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
    std.testing.expect(answer.part_2 == 1623178306) catch {
        print("{d} is not 1623178306\n", .{answer.part_2});
        failed = true;
    };
    try std.testing.expect(!failed);
}
