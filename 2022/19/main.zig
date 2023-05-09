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

const ResourcePile = struct {
    ore: u8 = 0,
    clay: u8 = 0,
    obsidian: u8 = 0,

    fn cloneWithDifference(self: *const ResourcePile, amounts: ResourcePile) ResourcePile {
        return ResourcePile{ .ore = self.ore - amounts.ore, .clay = self.clay - amounts.clay, .obsidian = self.obsidian - amounts.obsidian };
    }

    fn hasEnough(self: ResourcePile, amounts: ResourcePile) bool {
        return self.ore >= amounts.ore and self.clay >= amounts.clay and self.obsidian >= amounts.obsidian;
    }
};

const Blueprint = struct {
    ore_bot: ResourcePile,
    clay_bot: ResourcePile,
    obsidian_bot: ResourcePile,
    geode_bot: ResourcePile,
    max_costs: ResourcePile,

    pub fn fromStr(spec: str) Blueprint {
        const col_pos = std.mem.indexOfScalar(u8, spec, ':').?;
        var robots = std.mem.tokenize(u8, spec[col_pos..], ".");
        var bot_index: u8 = 0;
        var piles: [4]ResourcePile = undefined;
        var maxes = ResourcePile{};
        while (robots.next()) |bot| {
            var total_cost = ResourcePile{};
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
            maxes.ore = std.math.max(total_cost.ore, maxes.ore);
            maxes.clay = std.math.max(total_cost.clay, maxes.clay);
            maxes.obsidian = std.math.max(total_cost.obsidian, maxes.obsidian);
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

const State = struct {
    ticks: u8 = 0,
    ore_bots: u8 = 1,
    clay_bots: u8 = 0,
    obsidian_bots: u8 = 0,
    geode_bots: u8 = 0,
    geodes: u8 = 0,
    resources: ResourcePile = ResourcePile{},

    pub fn tickClone(self: State, expenditure: ?ResourcePile) State {
        var to_spend = ResourcePile{};
        if (expenditure) |actual_cost| {
            to_spend = actual_cost;
        }
        var new = State{ .ticks = self.ticks + 1, .ore_bots = self.ore_bots, .clay_bots = self.clay_bots, .obsidian_bots = self.obsidian_bots, .geode_bots = self.geode_bots, .geodes = self.geodes + self.geode_bots, .resources = self.resources.cloneWithDifference(to_spend) };
        new.resources.ore += self.ore_bots;
        new.resources.clay += self.clay_bots;
        new.resources.obsidian += self.obsidian_bots;
        return new;
    }

    pub fn format(
        self: State,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("T@{d},OB={d},CB={d},ObB={d},GB={d},G={d},R={}", .{ self.ticks, self.ore_bots, self.clay_bots, self.obsidian_bots, self.geode_bots, self.geodes, self.resources });
    }
};

/// This function is used in a priotity queue, which means returning Order.lt if "a" is more important,
/// Order.gt if "b" is more important, or Order.eq if it doesn't matter.
/// In run-of-the-mill pathfinding A*, this is usually done by comparing "FScores", and prioritising
/// states with lower values, because they represent likely cheaper/quicker paths.
/// For this problem though, all paths are the same "distance", and the more promising ones are
/// the ones that give more geodes/obsidian/clay. That's why we reverse a and b in the order
/// calls inside — bigger is better.
fn computePrioritisationHeuristic(_: *AutoHashMap(State, usize), a: State, b: State) std.math.Order {
    //TODO: Replace this mess with an elementwise comparison?
    const geode_compare = std.math.order(b.geodes, a.geodes);
    if (geode_compare == std.math.Order.eq) {
        const obs_compare = std.math.order(b.resources.obsidian, a.resources.obsidian);
        if (obs_compare == std.math.Order.eq) {
            const clay_compare = std.math.order(b.resources.clay, a.resources.clay);
            if (clay_compare == std.math.Order.eq) {
                return std.math.order(b.resources.ore, a.resources.ore);
            } else return clay_compare;
        } else return obs_compare;
    } else return geode_compare;
}

const AStarOpenSet = struct {
    q: PriorityQueue(State, *AutoHashMap(State, usize), computePrioritisationHeuristic),
    q_map: AutoHashMap(State, void),
    len: usize,

    fn init(allocator: Allocator, estimated_node_journey_costss: *AutoHashMap(State, usize)) AStarOpenSet {
        return AStarOpenSet{ .q = PriorityQueue(State, *AutoHashMap(State, usize), computePrioritisationHeuristic).init(allocator, estimated_node_journey_costss), .q_map = AutoHashMap(State, void).init(allocator), .len = 0 };
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
        var p = self.q.remove();
        _ = self.q_map.remove(p);
        self.len -= 1;
        return p;
    }
    fn contains(self: AStarOpenSet, state: State) bool {
        return self.q_map.contains(state);
    }
};

const BotChoice = enum { ore, clay, obsidian, geode, doNothing };
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
                        if (current_state.clay_bots < blueprint.max_costs.clay and current_state.resources.hasEnough(blueprint.clay_bot)) {
                            var clay_bot_made_state = current_state.tickClone(blueprint.clay_bot);
                            clay_bot_made_state.clay_bots += 1;
                            // print("--->Clay seems possible {}\n", .{clay_bot_made_state});
                            break :botloop clay_bot_made_state;
                        }
                    },
                    .clay => {
                        self.last_tried_neighbour = BotChoice.obsidian;
                        if (current_state.obsidian_bots < blueprint.max_costs.obsidian and current_state.resources.hasEnough(blueprint.obsidian_bot)) {
                            var obs_bot_made_state = current_state.tickClone(blueprint.obsidian_bot);
                            obs_bot_made_state.obsidian_bots += 1;
                            // print("--->Obsidian seems possible {}\n", .{obs_bot_made_state});
                            break :botloop obs_bot_made_state;
                        }
                    },
                    .obsidian => {
                        self.last_tried_neighbour = BotChoice.geode;
                        if (current_state.resources.hasEnough(blueprint.geode_bot)) {
                            var geode_bot_made_state = current_state.tickClone(blueprint.geode_bot);
                            geode_bot_made_state.geode_bots += 1;
                            // print("--->Geode seems possible {}\n", .{geode_bot_made_state});
                            break :botloop geode_bot_made_state;
                        }
                    },
                    .geode => {
                        // We can always do nothing
                        self.last_tried_neighbour = BotChoice.doNothing;
                        var idle_tick = current_state.tickClone(null);
                        // print("--->Idle thumbs it is {}\n", .{idle_tick});
                        break :botloop idle_tick;
                    },
                    .doNothing => {
                        break :botloop null;
                    },
                }
            }
            // Nothing yielded, try ore
            else {
                // print("Checking Neighbours For {}\n", .{self.current_state});
                self.last_tried_neighbour = BotChoice.ore;
                if (current_state.ore_bots < blueprint.max_costs.ore and current_state.resources.hasEnough(blueprint.ore_bot)) {
                    var ore_bot_made_state = current_state.tickClone(blueprint.ore_bot);
                    ore_bot_made_state.ore_bots += 1;
                    // print("--->Ore seems possible {}\n", .{ore_bot_made_state});
                    break :botloop ore_bot_made_state;
                }
            }
        };
        return next_neighbour;
    }
};

const Context = struct { blueprint: Blueprint, max_ticks: usize };

fn doAStarIsh(context: Context, allocator: Allocator, prog_node: *std.Progress.Node) !usize {
    const blueprint = context.blueprint;
    const starting_state = State{};

    var state_prog = std.Progress{ .root = prog_node.* };
    var state_prog_node = state_prog.start("States", 0);

    // In literature this is referred to as the "F score" because maths ¯\_(ツ)_/¯
    var estimated_node_journey_costs = AutoHashMap(State, usize).init(allocator);
    defer estimated_node_journey_costs.deinit();
    try estimated_node_journey_costs.put(starting_state, 0);

    // Referred to as the "open set" because it is the set of nodes open for
    // further investigation.
    var open_set = AStarOpenSet.init(allocator, &estimated_node_journey_costs);
    defer open_set.deinit();
    open_set.enqueue(starting_state);

    // In literature this is referred to as the "G score" because maths ¯\_(ツ)_/¯
    var confirmed_node_journey_costs = AutoHashMap(State, usize).init(allocator);
    defer confirmed_node_journey_costs.deinit();
    try confirmed_node_journey_costs.put(starting_state, 0);

    var current_state: State = undefined;

    var max_reached_geodes: usize = 0;

    while (open_set.len > 0) {
        current_state = open_set.pop();
        state_prog_node.completeOne();
        // print("Exploring {}\n", .{current_state});

        const ticks_remaining = context.max_ticks - current_state.ticks;
        if (current_state.geodes > max_reached_geodes) {
            max_reached_geodes = current_state.geodes;
        }
        try confirmed_node_journey_costs.put(current_state, current_state.geodes);

        // No time to bother with any subsequent states
        if (ticks_remaining == 0) continue;

        // The max possible geodes, assuming generously we could build a geode bot
        // every single tick, is the triangular number of the remaining ticks, plus
        // however many geode bots we have now multiplied by those ticks, plus
        // however many geodes we have now
        const theoretical_max_geodes = @divExact((ticks_remaining * (ticks_remaining + 1)), 2) + (current_state.geode_bots * ticks_remaining) + current_state.geodes;

        // print("ticks_remaining {d}, max_reached_geodes {d}, theoretical_max {d}\n", .{ ticks_remaining, max_reached_geodes, theoretical_max_geodes });
        if (theoretical_max_geodes <= max_reached_geodes) {
            // Nothing to see here, don't bother.
            // print("->>SKIPPING!\n", .{});
            continue;
        }

        // Don't bother with neighbours if there's no time
        var neighbours = NeighbourIterator{ .current_state = &current_state, .blueprint = &blueprint, .last_tried_neighbour = null };
        while (neighbours.next()) |neighbour| {
            // All states are 1 tick away from their neighbouring states
            // We aren't actually all that interested in shortest-path calculations here,
            // just to get the maximum value of geodes. If we've seen a state already,
            // don't bother with it again.
            var existing_cost_to_reach_neighbour = confirmed_node_journey_costs.get(neighbour);
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
        const best_geodes = try doAStarIsh(Context{ .blueprint = bp, .max_ticks = 24 }, allocator, p1_node);
        part_1 += (i + 1) * best_geodes;
        p1_node.completeOne();
    }
    p1_node.end();
    var part_2: usize = 1;
    var p2_node = root_progress.start("Part 2", 3);
    root_progress.refresh();
    for (blueprints.items[0..@min(3, blueprints.items.len)]) |bp| {
        const best_geodes = try doAStarIsh(Context{ .blueprint = bp, .max_ticks = 32 }, allocator, p2_node);
        part_2 *= best_geodes;
        p2_node.completeOne();
    }
    p2_node.end();

    return Answer{ .part_1 = part_1, .part_2 = part_2 };
}

fn doTheFirstOne(allocator: Allocator) !usize {
    var blueprints = std.ArrayList(Blueprint).init(allocator);
    defer blueprints.deinit();

    var lines = std.mem.tokenize(u8, example, "\n");
    while (lines.next()) |l| {
        blueprints.append(Blueprint.fromStr(l)) catch unreachable;
    }

    return try doAStarIsh(Context{ .blueprint = blueprints.items[0], .max_ticks = 24 }, allocator);
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
    var answer = try solve(example, std.testing.allocator);
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
