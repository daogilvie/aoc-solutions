const std = @import("std");
const utils = @import("aocutils");

const input = @embedFile("input.txt");
const example = @embedFile("test.txt");

const print = std.debug.print;

// Type shorthands
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const str = []const u8;

const Answer = utils.NumericAnswer(usize);

const Operation = enum {
    plus,
    minus,
    multiply,
    divide,
};

const CalculationMonkey = struct {
    lhs: str,
    operation: Operation,
    rhs: str,
};

const NumberMonkey = struct {
    number: usize,
};

const MonkeyJob = enum {
    number,
    calculation,
};

const MathMonkey = union(MonkeyJob) {
    number: NumberMonkey,
    calculation: CalculationMonkey,

    pub fn get_number(self: MathMonkey) ?usize {
        // If a number monkey, get the number, else return null.
        switch (self) {
            .number => |num_monkey| {
                return num_monkey.number;
            },
            .calculation => return null,
        }
    }
};

fn computeMonkey(bag_of_monkeys: *std.StringHashMap(MathMonkey), monkey_name: str) usize {
    const monkey = bag_of_monkeys.get(monkey_name).?;
    switch (monkey) {
        MonkeyJob.number => |number_monkey| return number_monkey.number,
        MonkeyJob.calculation => |calc_monkey| {
            const left = computeMonkey(bag_of_monkeys, calc_monkey.lhs);
            const right = computeMonkey(bag_of_monkeys, calc_monkey.rhs);
            return switch (calc_monkey.operation) {
                Operation.plus => left + right,
                Operation.minus => left - right,
                Operation.multiply => left * right,
                Operation.divide => @divFloor(left, right),
            };
        },
    }
}

fn normaliseMonkeyTree(bag_of_monkeys: *std.StringHashMap(MathMonkey), monkey_name: str) ?usize {
    // If we hit "humn" we need to return null, to signal this back up the tree
    if (std.mem.eql(u8, monkey_name, "humn")) return null;
    const monkey = bag_of_monkeys.get(monkey_name).?;
    switch (monkey) {
        MonkeyJob.number => |number_monkey| return number_monkey.number,
        MonkeyJob.calculation => |calc_monkey| {
            const left = normaliseMonkeyTree(bag_of_monkeys, calc_monkey.lhs);
            const right = normaliseMonkeyTree(bag_of_monkeys, calc_monkey.rhs);
            if (left == null or right == null) {
                // We've found the humn side of the tree and cannot proceed.
                return null;
            }
            const left_actual = left.?;
            const right_actual = right.?;
            if (std.mem.eql(u8, monkey_name, "root")) return null else {
                // Root is a special case, and we need to ignore the operation on it.
                const new_value = switch (calc_monkey.operation) {
                    Operation.plus => left_actual + right_actual,
                    Operation.minus => left_actual - right_actual,
                    Operation.multiply => left_actual * right_actual,
                    Operation.divide => @divFloor(left_actual, right_actual),
                };
                bag_of_monkeys.put(monkey_name, MathMonkey{ .number = NumberMonkey{ .number = new_value } }) catch unreachable;
                return new_value;
            }
        },
    }
}

fn calculateTarget(operation: Operation, target: isize, lhs: ?usize, rhs: ?usize) isize {
    const known_number: isize = @intCast(if (lhs == null) rhs.? else lhs.?);
    return switch (operation) {
        Operation.plus => target - known_number,
        Operation.minus => if (lhs == null) target + known_number else known_number - target,
        Operation.multiply => @divExact(target, known_number),
        Operation.divide => if (lhs == null) target * known_number else @divExact(known_number, target),
    };
}

fn determineHumanNumber(bag_of_monkeys: *std.StringHashMap(MathMonkey), monkey_name: str, target: isize) !isize {
    // This function keeps track of what is needed to achieve a target number
    // and balances a tree accordingly
    const monkey = bag_of_monkeys.get(monkey_name).?;
    switch (monkey) {
        // I don't think I'll ever actually call this into a number monkey
        MonkeyJob.number => return error.EhWhatNow,
        MonkeyJob.calculation => |calc_monkey| {
            const left_is_humn = std.mem.eql(u8, calc_monkey.lhs, "humn");
            const right_is_humn = std.mem.eql(u8, calc_monkey.rhs, "humn");
            // At some point, we'll reach humn, at which point the important thing
            // is the new target number
            if (left_is_humn or right_is_humn) {
                const lhs = if (left_is_humn) null else bag_of_monkeys.get(calc_monkey.lhs).?.get_number();
                const rhs = if (right_is_humn) null else bag_of_monkeys.get(calc_monkey.rhs).?.get_number();
                return calculateTarget(calc_monkey.operation, target, lhs, rhs);
            } else {
                const left = bag_of_monkeys.get(calc_monkey.lhs).?.get_number();
                const right = bag_of_monkeys.get(calc_monkey.rhs).?.get_number();
                // One of the above will be a number, the other is the tree we need to explore.
                const unknown_monkey = if (left == null) calc_monkey.lhs else calc_monkey.rhs;
                const new_target = calculateTarget(calc_monkey.operation, target, left, right);
                return try determineHumanNumber(bag_of_monkeys, unknown_monkey, new_target);
            }
        },
    }
}

pub fn solve(content: str, allocator: Allocator) !Answer {
    var lines = std.mem.tokenize(u8, content, "\n");
    var monkeymap = std.StringHashMap(MathMonkey).init(allocator);
    defer monkeymap.deinit();

    while (lines.next()) |line| {
        const col_pos = std.mem.indexOfScalar(u8, line, ':').?;
        const monkey_name = line[0..col_pos];

        var parts = std.mem.tokenize(u8, line[col_pos + 2 ..], " ");
        const first = parts.next().?;
        const middle = parts.next();
        if (middle) |operation_str| {
            // Calculation Monkey
            const operation = switch (operation_str[0]) {
                '+' => Operation.plus,
                '-' => Operation.minus,
                '*' => Operation.multiply,
                '/' => Operation.divide,
                else => return error.UnknownMonkeyOperation,
            };
            const rhs = parts.next().?;
            monkeymap.put(monkey_name, MathMonkey{ .calculation = CalculationMonkey{ .lhs = first, .operation = operation, .rhs = rhs } }) catch unreachable;
        } else {
            // Number Monkey
            const value: usize = std.fmt.parseInt(usize, line[col_pos + 2 ..], 10) catch unreachable;
            monkeymap.put(monkey_name, MathMonkey{ .number = NumberMonkey{ .number = value } }) catch unreachable;
        }
    }

    const part_1: usize = computeMonkey(&monkeymap, "root");

    // Normalise the monkey tree

    _ = normaliseMonkeyTree(&monkeymap, "root");

    const root_monkey = monkeymap.get("root").?;
    const part_2 = switch (root_monkey) {
        .number => return error.UWotM8,
        .calculation => |calc_monkey| blk: {
            const left = monkeymap.get(calc_monkey.lhs).?.get_number();
            const right = monkeymap.get(calc_monkey.rhs).?.get_number();
            // One of the monkeys is a number, the other needs exploring
            if (left == null) {
                break :blk try determineHumanNumber(&monkeymap, calc_monkey.lhs, @as(isize, @intCast(right.?)));
            } else {
                break :blk try determineHumanNumber(&monkeymap, calc_monkey.rhs, @as(isize, @intCast(left.?)));
            }
        },
    };

    return Answer{ .part_1 = part_1, .part_2 = @as(usize, @intCast(part_2)) };
}

pub fn main() !void {
    utils.printHeader("Day 21");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }
    var answer = solve(input, allocator) catch unreachable;
    answer.print();
}

test "day 21 worked examples" {
    const answer = try solve(example, std.testing.allocator);
    var failed = false;
    std.testing.expect(answer.part_1 == 152) catch {
        print("{d} is not 152\n", .{answer.part_1});
        failed = true;
    };
    std.testing.expect(answer.part_2 == 301) catch {
        print("{d} is not 301\n", .{answer.part_2});
        failed = true;
    };
    try std.testing.expect(!failed);
}
