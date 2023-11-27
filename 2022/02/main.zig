const std = @import("std");
const utils = @import("aocutils");

const input = @embedFile("input.txt");
const example = @embedFile("test.txt");

const Answer = utils.Answer;

const OpposingMove = enum(u8) {
    A = 1,
    B = 2,
    C = 3,

    pub fn getElementThatBeatsThis(self: OpposingMove) OpposingMove {
        const ordinal = std.math.rem(u8, @intFromEnum(self), 3) catch unreachable;
        return @enumFromInt(ordinal + 1);
    }

    pub fn getElementThatLosesToThis(self: OpposingMove) OpposingMove {
        const ordinal = std.math.rem(u8, @intFromEnum(self) + 1, 3) catch unreachable;
        return @enumFromInt(ordinal + 1);
    }
};

const GuideSuggestion = enum(u8) { X = 1, Y = 2, Z = 3 };

const winning_score: u8 = 6;
const drawing_score: u8 = 3;
const losing_score: u8 = 0;

fn calculateScoreOne(opponent_move: OpposingMove, suggestion: GuideSuggestion) usize {
    const their_ord = @intFromEnum(opponent_move);
    const my_ord = @intFromEnum(suggestion);
    const from_draw: u8 = if (their_ord == my_ord) drawing_score else 0;
    const from_win: u8 = switch (suggestion) {
        GuideSuggestion.X => if (opponent_move == OpposingMove.C) winning_score else 0,
        GuideSuggestion.Y => if (opponent_move == OpposingMove.A) winning_score else 0,
        GuideSuggestion.Z => if (opponent_move == OpposingMove.B) winning_score else 0,
    };
    return from_draw + from_win + my_ord;
}

fn calculateScoreTwo(opponent_move: OpposingMove, suggestion: GuideSuggestion) usize {
    return switch (suggestion) {
        GuideSuggestion.X => losing_score + @intFromEnum(opponent_move.getElementThatLosesToThis()),
        GuideSuggestion.Y => drawing_score + @intFromEnum(opponent_move),
        GuideSuggestion.Z => winning_score + @intFromEnum(opponent_move.getElementThatBeatsThis()),
    };
}

fn solve(contents: []const u8) !Answer {
    var score_one: usize = 0;
    var score_two: usize = 0;
    var entries = std.mem.tokenize(u8, contents, "\n ");

    while (entries.next()) |opponent| {
        const op_move = std.meta.stringToEnum(OpposingMove, opponent).?;
        const suggestion = std.meta.stringToEnum(GuideSuggestion, entries.next().?).?;
        score_one += calculateScoreOne(op_move, suggestion);
        score_two += calculateScoreTwo(op_move, suggestion);
    }

    return Answer{ .part_1 = score_one, .part_2 = score_two };
}

pub fn main() !void {
    utils.printHeader("Day 2");
    const answer = solve(input) catch unreachable;
    answer.print();
}

test "day 2 worked example" {
    const solution = try solve(example);
    try std.testing.expect(solution.part_1 == 15);
    try std.testing.expect(solution.part_2 == 12);
}
