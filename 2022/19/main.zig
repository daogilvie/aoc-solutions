const std = @import("std");
const utils = @import("aocutils");

const input = @embedFile("input.txt");
const example = @embedFile("test.txt");

const print = std.debug.print;

const MAXI: usize = std.math.maxInt(usize);

// Type shorthands
const str = []const u8;
const Allocator = std.mem.Allocator;
const PriorityQueue = std.PriorityQueue;
const AutoHashMap = std.AutoHashMap;

const Answer = utils.NumericAnswer(usize);

const ResType = enum { ore, clay, obsidian };
const BotChoice = enum { ore, clay, obsidian, geode, doNothing };

const RecipeCost = struct {
    ore: u8 = 0,
    clay: u8 = 0,
    obsidian: u8 = 0,
};

const ZERO_COSTS = RecipeCost{};

const Blueprint = struct {
    ore_bot: RecipeCost,
    clay_bot: RecipeCost,
    obsidian_bot: RecipeCost,
    geode_bot: RecipeCost,
    max_costs: RecipeCost,

    pub fn fromStr(spec: str) Blueprint {
        const col_pos = std.mem.indexOfScalar(u8, spec, ':').?;
        var robots = std.mem.tokenize(u8, spec[col_pos..], ".");
        var bot_index: u8 = 0;
        var piles: [4]RecipeCost = undefined;
        var maxes = RecipeCost{};
        while (robots.next()) |bot| {
            var total_cost = RecipeCost{};
            const costs_pos = std.mem.indexOf(u8, bot, "costs ").?;
            var costs = std.mem.split(u8, bot[costs_pos + 5 ..], " and ");
            while (costs.next()) |cost| {
                var parts = std.mem.tokenize(u8, cost, " ");
                const amount = std.fmt.parseInt(u8, parts.next().?, 10) catch unreachable;
                const t = std.meta.stringToEnum(ResType, parts.next().?).?;
                switch (t) {
                    .ore => total_cost.ore = amount,
                    .clay => total_cost.clay = amount,
                    .obsidian => total_cost.obsidian = amount,
                }
            }
            maxes.ore = @max(total_cost.ore, maxes.ore);
            maxes.clay = @max(total_cost.clay, maxes.clay);
            maxes.obsidian = @max(total_cost.obsidian, maxes.obsidian);
            piles[bot_index] = total_cost;
            bot_index += 1;
        }
        return Blueprint{ .ore_bot = piles[0], .clay_bot = piles[1], .obsidian_bot = piles[2], .geode_bot = piles[3], .max_costs = maxes };
    }

    pub fn format(
        self: Blueprint,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Ore bot: {d} Ore, {d} Clay, {d} Obsidian\n", .{ self.ore_bot.ore, self.ore_bot.clay, self.ore_bot.obsidian });
        try writer.print("Clay bot: {d} Ore, {d} Clay, {d} Obsidian\n", .{ self.clay_bot.ore, self.clay_bot.clay, self.clay_bot.obsidian });
        try writer.print("Obsidian bot: {d} Ore, {d} Clay, {d} Obsidian\n", .{ self.obsidian_bot.ore, self.obsidian_bot.clay, self.obsidian_bot.obsidian });
        try writer.print("Geode bot: {d} Ore, {d} Clay, {d} Obsidian\n", .{ self.geode_bot.ore, self.geode_bot.clay, self.geode_bot.obsidian });
        try writer.print("Max costs: {d} Ore, {d} Clay, {d} Obsidian\n", .{ self.max_costs.ore, self.max_costs.clay, self.max_costs.obsidian });
    }
};

const Assets = packed struct(u64) {
    geodes: u8 = 0,
    obsidian: u8 = 0,
    clay: u8 = 0,
    ore: u8 = 0,
    geode_bots: u8 = 0,
    obsidian_bots: u8 = 0,
    clay_bots: u8 = 0,
    ore_bots: u8 = 1,

    pub fn format(
        self: Assets,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("OB={d},CB={d},ObB={d},GB={d},G={d},Ob={d},C={d},O={d}", .{ self.ore_bots, self.clay_bots, self.obsidian_bots, self.geode_bots, self.geodes, self.obsidian, self.clay, self.ore });
    }

    pub fn hasEnough(self: Assets, cost: RecipeCost) bool {
        return self.ore >= cost.ore and self.clay >= cost.clay and self.obsidian >= cost.obsidian;
    }

    pub fn tick(self: *const Assets, blueprint: *const Blueprint, build_type: BotChoice) Assets {
        var new = Assets{
            .geodes = self.geodes + self.geode_bots,
            .obsidian = self.obsidian + self.obsidian_bots,
            .clay = self.clay + self.clay_bots,
            .ore = self.ore + self.ore_bots,
            .geode_bots = self.geode_bots,
            .obsidian_bots = self.obsidian_bots,
            .clay_bots = self.clay_bots,
            .ore_bots = self.ore_bots,
        };
        var costs: RecipeCost = ZERO_COSTS;
        switch (build_type) {
            .doNothing => {},
            .obsidian => {
                new.obsidian_bots += 1;
                costs = blueprint.obsidian_bot;
            },
            .clay => {
                new.clay_bots += 1;
                costs = blueprint.clay_bot;
            },
            .ore => {
                new.ore_bots += 1;
                costs = blueprint.ore_bot;
            },
            .geode => {
                new.geode_bots += 1;
                costs = blueprint.geode_bot;
            },
        }

        new.ore -= costs.ore;
        new.clay -= costs.clay;
        new.obsidian -= costs.obsidian;

        return new;
    }
};

const State = struct {
    ticks: u8 = 0,
    things: Assets = Assets{},
    ctx: *const Blueprint,

    pub fn format(
        self: State,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("T@{d},{}", .{ self.ticks, self.things });
    }

    pub fn tickClone(self: State, build_type: BotChoice) State {
        return State{ .ticks = self.ticks + 1, .things = self.things.tick(self.ctx, build_type), .ctx = self.ctx };
    }
};

/// This function is used in a priotity queue, which means returning Order.lt if "a" is more important,
/// Order.gt if "b" is more important, or Order.eq if it doesn't matter.
/// For this problem, all paths are the same "distance", and the more promising ones are
/// the ones that give more geodes/obsidian/clay. That's why we reverse a and b in the order
/// calls inside — bigger is better. A and B are also packed structs designed explicitly
/// to work with this ordering.
fn computePrioritisationHeuristic(_: void, a: State, b: State) std.math.Order {
    // The structs are aligned such that we can just compare them as ints
    return std.math.order(@as(u64, @bitCast(b.things)), @as(u64, @bitCast(a.things)));
}

const AStarOpenSet = struct {
    q: PriorityQueue(State, void, computePrioritisationHeuristic),
    q_map: AutoHashMap(State, void),
    len: usize,

    fn init(allocator: Allocator) AStarOpenSet {
        return AStarOpenSet{ .q = PriorityQueue(State, void, computePrioritisationHeuristic).init(allocator, {}), .q_map = AutoHashMap(State, void).init(allocator), .len = 0 };
    }
    fn deinit(self: *AStarOpenSet) void {
        self.q.deinit();
        self.q_map.deinit();
    }

    fn enqueue(self: *AStarOpenSet, state: State) void {
        self.q_map.put(state, {}) catch unreachable;
        self.q.add(state) catch unreachable;
        self.len += 1;
    }
    fn pop(self: *AStarOpenSet) State {
        const p = self.q.remove();
        _ = self.q_map.remove(p);
        self.len -= 1;
        return p;
    }
    fn contains(self: AStarOpenSet, state: State) bool {
        return self.q_map.contains(state);
    }
};

const NeighbourIterator = struct {
    current_state: *const State,
    blueprint: *const Blueprint,
    last_tried_neighbour: ?BotChoice,

    pub fn next(self: *NeighbourIterator) ?State {
        const current_state = self.current_state.*;
        const blueprint = self.blueprint.*;

        var next_neighbour: ?State = null;
        next_neighbour = botloop: while (next_neighbour == null) {
            if (self.last_tried_neighbour) |last| {
                switch (last) {
                    .ore => {
                        self.last_tried_neighbour = BotChoice.clay;
                        if (current_state.things.clay_bots < blueprint.max_costs.clay and current_state.things.hasEnough(blueprint.clay_bot)) {
                            const clay_bot_made_state = current_state.tickClone(BotChoice.clay);
                            break :botloop clay_bot_made_state;
                        }
                    },
                    .clay => {
                        self.last_tried_neighbour = BotChoice.obsidian;
                        if (current_state.things.obsidian_bots < blueprint.max_costs.obsidian and current_state.things.hasEnough(blueprint.obsidian_bot)) {
                            const obs_bot_made_state = current_state.tickClone(BotChoice.obsidian);
                            break :botloop obs_bot_made_state;
                        }
                    },
                    .obsidian => {
                        self.last_tried_neighbour = BotChoice.geode;
                        if (current_state.things.hasEnough(blueprint.geode_bot)) {
                            const geode_bot_made_state = current_state.tickClone(BotChoice.geode);
                            break :botloop geode_bot_made_state;
                        }
                    },
                    .geode => {
                        // We can always do nothing
                        self.last_tried_neighbour = BotChoice.doNothing;
                        const idle_tick = current_state.tickClone(BotChoice.doNothing);
                        break :botloop idle_tick;
                    },
                    .doNothing => {
                        break :botloop null;
                    },
                }
            }
            // Nothing yielded, try ore
            else {
                self.last_tried_neighbour = BotChoice.ore;
                if (current_state.things.ore_bots < blueprint.max_costs.ore and current_state.things.hasEnough(blueprint.ore_bot)) {
                    const ore_bot_made_state = current_state.tickClone(BotChoice.ore);
                    break :botloop ore_bot_made_state;
                }
            }
        } else null;
        return next_neighbour;
    }
};

const Context = struct { blueprint: Blueprint, max_ticks: usize };

fn exploreStateSpace(context: Context, allocator: Allocator, prog_node: *std.Progress.Node) !usize {
    const blueprint = context.blueprint;
    const starting_state = State{ .ctx = &context.blueprint };

    var state_prog = std.Progress{ .root = prog_node.* };
    var state_prog_node = state_prog.start("States", 0);

    // Referred to as the "open set" because it is the set of nodes open for
    // further investigation.
    var open_set = AStarOpenSet.init(allocator);
    defer open_set.deinit();
    open_set.enqueue(starting_state);

    // In literature this is referred to as the "G score" because maths ¯\_(ツ)_/¯
    var confirmed_geode_amounts = AutoHashMap(State, void).init(allocator);
    defer confirmed_geode_amounts.deinit();
    try confirmed_geode_amounts.put(starting_state, {});

    var current_state: State = undefined;

    var max_reached_geodes: usize = 0;

    while (open_set.len > 0) {
        current_state = open_set.pop();
        state_prog_node.completeOne();

        const ticks_remaining = context.max_ticks - current_state.ticks;
        if (current_state.things.geodes > max_reached_geodes) {
            max_reached_geodes = current_state.things.geodes;
        }
        try confirmed_geode_amounts.put(current_state, {});

        // No time to bother with any subsequent states
        if (ticks_remaining == 0) continue;

        // The max possible geodes, assuming generously we could build a geode bot
        // every single tick, is the triangular number of the remaining ticks, plus
        // however many geode bots we have now multiplied by those ticks, plus
        // however many geodes we have now
        const theoretical_max_geodes = @divExact((ticks_remaining * (ticks_remaining + 1)), 2) + (current_state.things.geode_bots * ticks_remaining) + current_state.things.geodes;

        if (theoretical_max_geodes <= max_reached_geodes) {
            // Nothing to see here, don't bother.
            continue;
        }

        // Don't bother with neighbours if there's no time
        var neighbours = NeighbourIterator{ .current_state = &current_state, .blueprint = &blueprint, .last_tried_neighbour = null };
        while (neighbours.next()) |neighbour| {
            // All states are 1 tick away from their neighbouring states
            // We aren't actually all that interested in shortest-path calculations here,
            // just to get the maximum value of geodes. If we've seen a state already,
            // don't bother with it again, as it can't give us any new info.
            const existing_cost_to_reach_neighbour = confirmed_geode_amounts.get(neighbour);
            if (existing_cost_to_reach_neighbour == null and !open_set.contains(neighbour)) {
                open_set.enqueue(neighbour);
            }
        }
    }

    state_prog_node.end();

    return max_reached_geodes;
}

pub fn solve(content: str, allocator: Allocator) !Answer {
    var blueprints = std.ArrayList(Blueprint).init(allocator);
    defer blueprints.deinit();

    var lines = std.mem.tokenize(u8, content, "\n");
    while (lines.next()) |l| {
        blueprints.append(Blueprint.fromStr(l)) catch unreachable;
    }

    var root_progress = std.Progress{};
    var p1_node = root_progress.start("Part 1", blueprints.items.len);
    root_progress.refresh();
    var part_1: usize = 0;
    for (blueprints.items, 0..) |bp, i| {
        const best_geodes = try exploreStateSpace(Context{ .blueprint = bp, .max_ticks = 24 }, allocator, p1_node);
        part_1 += (i + 1) * best_geodes;
        p1_node.completeOne();
    }
    p1_node.end();
    var part_2: usize = 1;
    var p2_node = root_progress.start("Part 2", 3);
    root_progress.refresh();
    for (blueprints.items[0..@min(3, blueprints.items.len)]) |bp| {
        const best_geodes = try exploreStateSpace(Context{ .blueprint = bp, .max_ticks = 32 }, allocator, p2_node);
        part_2 *= best_geodes;
        p2_node.completeOne();
    }
    p2_node.end();

    return Answer{ .part_1 = part_1, .part_2 = part_2 };
}

pub fn main() !void {
    utils.printHeader("Day 19");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }
    var answer = solve(input, allocator) catch unreachable;
    answer.print();
}

test "day 19 worked examples" {
    const answer = try solve(example, std.testing.allocator);
    var failed = false;
    std.testing.expect(answer.part_1 == 33) catch {
        print("{d} is not 33\n", .{answer.part_1});
        failed = true;
    };
    std.testing.expect(answer.part_2 == 3472) catch {
        print("{d} is not 3472\n", .{answer.part_1});
        failed = true;
    };
    try std.testing.expect(!failed);
}
