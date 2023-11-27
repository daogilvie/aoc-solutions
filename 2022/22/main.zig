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

const WallType = enum {
    emptiness,
    walkable,
    blocked,
};

const InstructionType = enum { turn, move };

const TurnDirection = enum { R, L };

const Instruction = union(InstructionType) { turn: TurnDirection, move: usize };

const InstructionParserState = struct { input: str, index: usize = 0 };

const State = struct {
    instructions: ArrayList(Instruction),
    current_instruction: usize = 0,
};

fn parseInstructions(spec: str, allocator: Allocator) ArrayList(Instruction) {
    var parsed = ArrayList(Instruction).init(allocator);
    const trimmed = std.mem.trim(u8, spec, "\n ");

    var state = InstructionParserState{ .input = trimmed };
    while (state.index < state.input.len) {
        const move = attemptParseMove(&state);
        if (move) |move_actual| {
            parsed.append(move_actual) catch unreachable;
        } else {
            const turn = attemptParseTurn(&state);
            if (turn) |turn_actual| {
                parsed.append(turn_actual) catch unreachable;
            } else unreachable;
        }
    }

    return parsed;
}

fn attemptParseMove(state: *InstructionParserState) ?Instruction {
    var curr = state.index;
    // Early fail if not a digit
    if (!std.ascii.isDigit(state.input[curr])) {
        return null;
    }
    // Can consume at least one digit
    while (std.ascii.isDigit(state.input[curr]) and curr < state.input.len) {
        curr += 1;
        if (curr == state.input.len) break;
    }
    const steps = std.fmt.parseInt(usize, state.input[state.index..curr], 10) catch unreachable;
    state.*.index = curr;
    return Instruction{ .move = steps };
}

fn attemptParseTurn(state: *InstructionParserState) ?Instruction {
    const attempted = std.meta.stringToEnum(TurnDirection, state.input[state.index .. state.index + 1]);
    if (attempted) |turn_dir| {
        state.*.index += 1;
        return Instruction{ .turn = turn_dir };
    } else {
        return null;
    }
}

const Facing = enum {
    Right,
    Down,
    Left,
    Up,

    pub fn turnRight(self: Facing) Facing {
        return switch (self) {
            Facing.Right => Facing.Down,
            Facing.Down => Facing.Left,
            Facing.Left => Facing.Up,
            Facing.Up => Facing.Right,
        };
    }

    pub fn turnLeft(self: Facing) Facing {
        return switch (self) {
            Facing.Right => Facing.Up,
            Facing.Down => Facing.Right,
            Facing.Left => Facing.Down,
            Facing.Up => Facing.Left,
        };
    }

    pub fn value(self: Facing) usize {
        return switch (self) {
            Facing.Right => 0,
            Facing.Down => 1,
            Facing.Left => 2,
            Facing.Up => 3,
        };
    }

    pub fn repr(self: Facing) u8 {
        return switch (self) {
            Facing.Right => '>',
            Facing.Down => 'v',
            Facing.Left => '<',
            Facing.Up => '^',
        };
    }
};

const Map = struct {
    cells: []u8,
    cols: usize,
    rows: usize,
    allocator: Allocator,
    current_col: usize = 0,
    current_row: usize = 0,
    current_facing: Facing = Facing.Right,

    pub fn deinit(self: *Map) void {
        self.allocator.free(self.cells);
    }

    pub fn current_cell_contents(self: *const Map) u8 {
        return self.cells[self.current_row * self.cols + self.current_col];
    }

    pub fn set_current_cell_contents(self: *Map, new: u8) void {
        self.cells[self.current_row * self.cols + self.current_col] = new;
    }

    pub fn step(self: *Map) void {
        var col = self.current_col;
        var row = self.current_row;
        switch (self.current_facing) {
            Facing.Right => {
                if (col == self.cols - 1) col = 0 else col += 1;
            },
            Facing.Down => {
                if (row == self.rows - 1) row = 0 else row += 1;
            },
            Facing.Left => {
                if (col > 0) col -= 1 else col = self.cols - 1;
            },
            Facing.Up => {
                if (row > 0) row -= 1 else row = self.rows - 1;
            },
        }
        self.current_row = row;
        self.current_col = col;
    }

    pub fn step_wrapped(self: *Map) bool {
        const row = self.current_row;
        const col = self.current_col;
        // Mark it
        self.set_current_cell_contents(self.current_facing.repr());
        self.step();
        var current = self.current_cell_contents();
        // Check if we need to sliiiiide along the void
        if (current == ' ') {
            while (current == ' ') {
                self.step();
                current = self.current_cell_contents();
            }
        }

        // Have we hit a wall? Reset.
        if (current == '#') {
            // Cannot move, so just reset and return
            self.current_row = row;
            self.current_col = col;
            return false;
        }
        self.set_current_cell_contents('@');
        return true;
    }

    pub fn step_cubenet(self: *Map) bool {
        const row = self.current_row;
        const col = self.current_col;
        const right_edge = @mod(col, self.region_size - 1) == 0;
        _ = right_edge;
        const down_edge = @mod(row, self.region_size - 1) == 0;
        _ = down_edge;
        const left_edge = @mod(col, self.region_size) == 0;
        _ = left_edge;
        const up_edge = @mod(row, self.region_size) == 0;
        _ = up_edge;
        // Mark it
        self.set_current_cell_contents(self.current_facing.repr());
        self.step();
        var current = self.current_cell_contents();
        // Check if we need to sliiiiide along the void
        if (current == ' ') {
            while (current == ' ') {
                self.step();
                current = self.current_cell_contents();
            }
        }

        // Have we hit a wall? Reset.
        if (current == '#') {
            // Cannot move, so just reset and return
            self.current_row = row;
            self.current_col = col;
            return false;
        }
        self.set_current_cell_contents('@');
        return true;
    }

    pub fn format(
        self: Map,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        for (0..self.rows) |row| {
            const row_start = row * self.cols;
            const row_end = row_start + self.cols;
            try writer.print("{s}\n", .{self.cells[row_start..row_end]});
        }
    }
};

fn parseMap(spec: str, allocator: Allocator) Map {
    // First determine the dimensions
    var row_count: usize = 0;
    var col_count: usize = 0;
    var rows = std.mem.tokenize(u8, spec, "\n");
    while (rows.next()) |row| {
        row_count += 1;
        col_count = @max(col_count, row.len);
    }

    var start_col: ?usize = null;

    var cells = allocator.alloc(u8, row_count * col_count) catch unreachable;

    // Go around again, parsing each row.
    rows = std.mem.tokenize(u8, spec, "\n");
    var row_index: usize = 0;
    while (rows.next()) |row| {
        for (0..col_count) |col_index| {
            const cell_index = row_index * col_count + col_index;
            if (col_index < row.len) {
                if (row_index == 0 and start_col == null and row[col_index] == '.') {
                    start_col = col_index;
                }
                cells[cell_index] = row[col_index];
            } else cells[cell_index] = ' ';
        }
        row_index += 1;
    }

    return Map{ .cells = cells, .rows = row_count, .cols = col_count, .current_col = start_col.?, .allocator = allocator };
}

fn followInstructions(instructions: ArrayList(Instruction), map: *Map) void {
    for (instructions.items, 0..) |instruction, idx| {
        switch (instruction) {
            InstructionType.move => |amount| {
                for (0..amount) |_| {
                    // If false, we have hit a wall and should stop.
                    if (!map.step_wrapped()) break;
                }
                _ = idx;
                // print("{[1]d:->[2]}\n{[0]}\n", .{ map.*, idx, map.cols });
            },
            InstructionType.turn => |direction| {
                switch (direction) {
                    TurnDirection.R => {
                        map.current_facing = map.current_facing.turnRight();
                    },
                    TurnDirection.L => {
                        map.current_facing = map.current_facing.turnLeft();
                    },
                }
            },
        }
    }
}

pub fn solve(content: str, allocator: Allocator) !Answer {
    var halves = std.mem.split(u8, content, "\n\n");
    // First half is the map spec
    // Second half is the instructions
    const map_spec = halves.next().?;
    const instructions = parseInstructions(halves.next().?, allocator);
    defer instructions.deinit();

    var map = parseMap(map_spec, allocator);

    followInstructions(instructions, &map);

    const part_1: usize = map.current_facing.value() + 1000 * (map.current_row + 1) + 4 * (map.current_col + 1);

    // Re-parse the map to reset
    map.deinit();
    map = parseMap(map_spec, allocator);
    defer map.deinit();

    const part_2: usize = map.current_facing.value() + 1000 * (map.current_row + 1) + 4 * (map.current_col + 1);
    return Answer{ .part_1 = part_1, .part_2 = part_2 };
}

pub fn main() !void {
    utils.printHeader("Day 22");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }
    var answer = solve(input, allocator) catch unreachable;
    answer.print();
}

test "day 22 worked examples" {
    const answer = try solve(example, std.testing.allocator);
    var failed = false;
    std.testing.expect(answer.part_1 == 6032) catch {
        print("{d} is not 6032\n", .{answer.part_1});
        failed = true;
    };
    std.testing.expect(answer.part_2 == 5031) catch {
        print("{d} is not 5031\n", .{answer.part_2});
        failed = true;
    };
    try std.testing.expect(!failed);
}
