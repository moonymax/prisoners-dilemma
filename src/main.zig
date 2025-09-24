const prisoners_dilemma = @import("prisoners_dilemma");
const std = @import("std");
var prng = std.Random.DefaultPrng.init(42);

fn toFloat(input: u16) f32 {
    return @as(f32, @floatFromInt(input));
}

fn toInt(input: f32) u16 {
    return @as(u16, @intFromFloat(input));
}

fn random_float_zero_one() f32 {
    return prng.random().float(f32);
}

const Prisoner = struct {
    forgiveness: f32,
    score: f32,
};

// many strategies different forgiveness percentages
// many agents with a strategy
// many rounds of interactions with other random agents
//  reward for interacting or defecting
//          a coop | a defect
// b coop        1 | 2
// b defect      2 | 0

// integer to identify how the interaction went
//          a coop | a defect
// b coop        0 | 1
// b defect      2 | 3

const Action = enum { Betray, Cooperate };

const Strategy = enum { TitForTat, AlwaysBetray };

const StrategyError = error{InvalidStrategy};

fn titForTat(opponents_history: *std.array_list.Managed(Action)) Action {
    return if (opponents_history.items.len > 0) opponents_history.items[opponents_history.items.len - 1] else Action.Cooperate;
}

fn apply_strategy(opponents_history: *std.array_list.Managed(Action), strategy: Strategy) !Action {
    switch (strategy) {
        Strategy.AlwaysBetray => {
            return Action.Betray;
        },
        Strategy.TitForTat => {
            return titForTat(opponents_history);
        },
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const actions_length: u8 = 30;

    var interactions_map = std.hash_map.AutoHashMap(u64, *std.array_list.Managed(Action)).init(allocator);
    defer interactions_map.deinit();

    var score_prisoner_a: u16 = 0;
    var actions_prisoner_a = std.array_list.Managed(Action).init(allocator);
    defer actions_prisoner_a.deinit();

    var score_prisoner_b: u16 = 0;
    var actions_prisoner_b = std.array_list.Managed(Action).init(allocator);
    defer actions_prisoner_b.deinit();

    var actions_pointer: u8 = 0;

    while (actions_pointer < actions_length) : (actions_pointer += 1) {
        // a always betrays and so doesnt need the previous action of b

        // strategy of b = copy the last action of a
        // strategy of a = betray

        const new_action_a = try apply_strategy(&actions_prisoner_b, Strategy.TitForTat);
        const new_action_b = try apply_strategy(&actions_prisoner_a, Strategy.AlwaysBetray);

        try actions_prisoner_a.append(new_action_a);
        try actions_prisoner_b.append(new_action_b);

        // based on the score matrix we add the new scores to the prisoners scores
        //  reward for interacting or defecting
        //          a coop | a defect
        // b coop        1 | 2
        // b defect      2 | 0
        if (new_action_a == Action.Cooperate and new_action_b == Action.Cooperate) {
            score_prisoner_a += 1;
            score_prisoner_b += 1;
        } else if (new_action_a == Action.Betray and new_action_b == Action.Betray) {
            // This is just here for sake of completeness
            score_prisoner_a += 0;
            score_prisoner_b += 0;
        } else if (new_action_a == Action.Betray and new_action_b == Action.Cooperate) {
            score_prisoner_a += 2;
            score_prisoner_b += 0;
        } else if (new_action_a == Action.Cooperate and new_action_b == Action.Betray) {
            score_prisoner_a += 0;
            score_prisoner_b += 2;
        }
    }

    std.debug.print("prisoner a actions: {any} final score: {any}\n", .{ actions_prisoner_a, score_prisoner_a });
    std.debug.print("prisoner b actions: {any} final score: {any}\n", .{ actions_prisoner_b, score_prisoner_b });

    //     const randomPrisoner1Index: u16 = toInt(std.math.floor(random_float_zero_one() * toFloat(numberOfPrisoners)));
    //     const randomPrisoner2Index: u16 = toInt(std.math.floor(random_float_zero_one() * toFloat(numberOfPrisoners)));
}

// test "simple test" {
//     const gpa = std.testing.allocator;
//     var list: std.ArrayList(i32) = .empty;
//     defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
//     try list.append(gpa, 42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }

// test "fuzz example" {
//     const Context = struct {
//         fn testOne(context: @This(), input: []const u8) anyerror!void {
//             _ = context;
//             // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
//             try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
//         }
//     };
//     try std.testing.fuzz(Context{}, Context.testOne, .{});
// }
