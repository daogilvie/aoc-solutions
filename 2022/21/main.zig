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
    const part_2: usize = 0;

    return Answer{ .part_1 = part_1, .part_2 = part_2 };
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
    var answer = try solve(example, std.testing.allocator);
    var failed = false;
    std.testing.expect(answer.part_1 == 152) catch {
        print("{d} is not 152\n", .{answer.part_1});
        failed = true;
    };
    try std.testing.expect(!failed);
}
