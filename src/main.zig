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
    strategy: Strategy,
    score: u32,
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

const Strategy = enum { TitForTat, AlwaysBetray, TitForTatBetrayLast, TitForTat10pctForgiveness };

const StrategyError = error{InvalidStrategy};

fn titForTat(opponents_history: *const std.array_list.Managed(Action)) Action {
    return if (opponents_history.items.len > 0) opponents_history.items[opponents_history.items.len - 1] else Action.Cooperate;
}

fn titForTat10pctForgiveness(opponents_history: *const std.array_list.Managed(Action)) Action {
    const action_previous = if (opponents_history.items.len > 0) opponents_history.items[opponents_history.items.len - 1] else Action.Cooperate;
    if (action_previous == Action.Cooperate) {
        return Action.Cooperate;
    }

    // we forgive 10pct of the time
    const should_forgive = random_float_zero_one() < 0.9;
    if (action_previous == Action.Betray and should_forgive) {
        return Action.Cooperate;
    }

    return Action.Betray;
}

fn titForTatBetrayLast(opponents_history: *const std.array_list.Managed(Action)) Action {
    if (opponents_history.items.len < 29) {
        return titForTat(opponents_history);
    } else {
        return Action.Betray;
    }
}

fn apply_strategy(opponents_history: *const std.array_list.Managed(Action), strategy: Strategy) !Action {
    switch (strategy) {
        Strategy.AlwaysBetray => {
            return Action.Betray;
        },
        Strategy.TitForTat => {
            return titForTat(opponents_history);
        },
        Strategy.TitForTatBetrayLast => {
            return titForTatBetrayLast(opponents_history);
        },
        Strategy.TitForTat10pctForgiveness => {
            return titForTat10pctForgiveness(opponents_history);
        },
    }
}

fn comparePrisonersByScore(context: void, a: Prisoner, b: Prisoner) bool {
    // The context argument is often unused, so we name it '_' to avoid warnings.
    _ = context;

    return a.score < b.score;
}

const number_of_strategies = @typeInfo(Strategy).@"enum".fields.len;

const index_to_strategy = [number_of_strategies]Strategy{ Strategy.AlwaysBetray, Strategy.TitForTat, Strategy.TitForTatBetrayLast, Strategy.TitForTat10pctForgiveness };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const interactions_per_pairing: u8 = 30;

    var interactions_map = std.hash_map.AutoHashMap(u64, std.array_list.Managed(Action)).init(allocator);
    try interactions_map.ensureTotalCapacity(130_000);
    defer interactions_map.deinit();

    const number_of_prisoners: u16 = 1000;

    var prisoners = std.array_list.Managed(Prisoner).init(allocator);
    defer prisoners.deinit();

    var prisoner_counter: u16 = 0;
    while (prisoner_counter < number_of_prisoners) : (prisoner_counter += 1) {
        //                                                                      based in the index this prsoner gets a strategy
        //                                                                      prisoner_counter % number_of_strategies gives use wrap around behaviour incase the index is larger than the number of strategies we have
        try prisoners.append(Prisoner{ .score = 0, .strategy = index_to_strategy[prisoner_counter % number_of_strategies] });
    }

    const PAIRINGS_PER_ROUND: u32 = 100_000;

    var pairings_counter: u32 = 0;
    while (pairings_counter < PAIRINGS_PER_ROUND) : (pairings_counter += 1) {
        // 1. get two random prisoners
        // the actions will be of the prisoner with the small bits in the index
        // this also means that prisoner A will always have to be the one with the smaller index and B with the bigger index
        const index_prisoner_A = toInt(random_float_zero_one() * toFloat(number_of_prisoners));
        const index_prisoner_B = toInt(random_float_zero_one() * toFloat(number_of_prisoners));

        // if they are the same order doesnt matter
        var prisoner_A = &prisoners.items[index_prisoner_A];
        var prisoner_B = &prisoners.items[index_prisoner_B];

        // 2. make them interact 30 or so times

        // get the interaction history
        // interaction history is always from perspective of prisoner a

        const key_actions_prisoner_A: u32 = @as(u32, index_prisoner_A) + @as(u32, index_prisoner_B) * (std.math.maxInt(u16) + 1);
        const key_actions_prisoner_B: u32 = @as(u32, index_prisoner_B) + @as(u32, index_prisoner_A) * (std.math.maxInt(u16) + 1);

        const maybe_history_actions_prisoner_A = try interactions_map.getOrPut(key_actions_prisoner_A);
        const maybe_history_actions_prisoner_B = try interactions_map.getOrPut(key_actions_prisoner_B);

        if (!maybe_history_actions_prisoner_A.found_existing) {
            maybe_history_actions_prisoner_A.value_ptr.* = std.array_list.Managed(Action).init(allocator);
        }
        if (!maybe_history_actions_prisoner_B.found_existing) {
            maybe_history_actions_prisoner_B.value_ptr.* = std.array_list.Managed(Action).init(allocator);
        }

        var history_actions_prisoner_A = maybe_history_actions_prisoner_A.value_ptr;
        var history_actions_prisoner_B = maybe_history_actions_prisoner_B.value_ptr;

        // 3. run through all the interactions between the two prisoners

        var interactions_counter: u8 = 0;

        while (interactions_counter < interactions_per_pairing) : (interactions_counter += 1) {
            const new_action_prisoner_A = try apply_strategy(history_actions_prisoner_B, prisoner_A.strategy);
            const new_action_prisoner_B = try apply_strategy(history_actions_prisoner_A, prisoner_B.strategy);

            // here we introduce signal error -> evaluation happens based on the real action but signal error is applied when saving
            const SIGNAL_ERROR_RATE = 0.9;

            const with_signal_error_new_action_prisoner_A = if (random_float_zero_one() < SIGNAL_ERROR_RATE) Action.Betray else new_action_prisoner_A;
            const with_signal_error_new_action_prisoner_B = if (random_float_zero_one() < SIGNAL_ERROR_RATE) Action.Betray else new_action_prisoner_B;
            try history_actions_prisoner_A.append(with_signal_error_new_action_prisoner_A);
            try history_actions_prisoner_B.append(with_signal_error_new_action_prisoner_B);

            // based on the score matrix we add the new scores to the prisoners scores
            //  reward for interacting or defecting
            //          a coop | a defect
            // b coop        1 | 2
            // b defect      2 | 0
            if (new_action_prisoner_A == Action.Cooperate and new_action_prisoner_B == Action.Cooperate) {
                prisoner_A.score += 1;
                prisoner_B.score += 1;
            } else if (new_action_prisoner_A == Action.Betray and new_action_prisoner_B == Action.Betray) {
                // This is just here for sake of completeness
                prisoner_A.score += 0;
                prisoner_B.score += 0;
            } else if (new_action_prisoner_A == Action.Betray and new_action_prisoner_B == Action.Cooperate) {
                prisoner_A.score += 2;
                prisoner_B.score += 0;
            } else if (new_action_prisoner_A == Action.Cooperate and new_action_prisoner_B == Action.Betray) {
                prisoner_A.score += 0;
                prisoner_B.score += 2;
            }
        }
    }

    // Immediately deallocate all the entries after the loop
    var interactions_map_iterator = interactions_map.iterator();

    defer while (interactions_map_iterator.next()) |entry| {
        const array_list_pointer = entry.value_ptr;
        array_list_pointer.*.deinit();
    };

    // Displaying the highest scoring for each strategy

    // A hash map to store the highest-scoring prisoner for each strategy
    var highest_scores = std.AutoHashMap(Strategy, Prisoner).init(allocator);
    defer highest_scores.deinit();

    // Iterate through all prisoners to find the highest score for each strategy
    for (prisoners.items) |prisoner| {
        if (highest_scores.get(prisoner.strategy)) |existing_prisoner| {
            // Found an entry, compare scores and update if higher
            if (prisoner.score > existing_prisoner.score) {
                try highest_scores.put(prisoner.strategy, prisoner);
            }
        } else {
            // First time seeing this strategy, add it to the map
            try highest_scores.put(prisoner.strategy, prisoner);
        }
    }

    // Iterate through the hash map and print the results
    var iterator = highest_scores.iterator();
    while (iterator.next()) |entry| {
        std.debug.print("Highest-scoring {any}: {d}\n", .{ entry.key_ptr.*, entry.value_ptr.*.score });
    }
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
