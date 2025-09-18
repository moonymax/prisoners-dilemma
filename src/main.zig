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

const Interaction = struct { aIndex: usize, bIndex: usize, result: usize };

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

fn interact(a: Prisoner, b: Prisoner, interactionHistory: *const std.ArrayList(u8)) u8 {
    const lastInteraction = interactionHistory.items[interactionHistory.items.len - 1];

    // if the interaction is odd the a defected
    const didADefect = lastInteraction % 2 == 1;
    // if its 2 or 3 then b defected
    const didBDefect = lastInteraction == 2 or lastInteraction == 3;

    // TODO: These have to be replaced with a strategy function where each prisoner can have a strategy
    // TODO: each strategy should be identified using an enum -> a function will then run the strategy using that enum

    // cooperate if b cooperated last else defect unless random value hits forgiveness threshold
    const isNewAChoiceCooperate = if (didBDefect) random_float_zero_one() < a.forgiveness else true;
    const isNewBChoiceCooperate = if (didADefect) random_float_zero_one() < b.forgiveness else true;

    // could also be done using some binary arithmetic instead
    if (isNewAChoiceCooperate and isNewBChoiceCooperate) {
        return 0;
    } else if (!isNewAChoiceCooperate and isNewBChoiceCooperate) {
        return 1;
    } else if (isNewAChoiceCooperate and !isNewBChoiceCooperate) {
        return 2;
    } else {
        return 3;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const numberOfPrisoners: u16 = 1000;

    var prisoners: [numberOfPrisoners]Prisoner = undefined;

    var i: u16 = 0;
    while (i < numberOfPrisoners) : (i += 1) {
        // uniform distribution of forgiveness
        const forgiveness = 1.0 / toFloat(numberOfPrisoners) * toFloat(i);
        prisoners[i] = Prisoner{ .forgiveness = forgiveness, .score = 1 };
    }

    // prisoners are initialized
    // pick two and let them iteract
    // store the interaction in an array and use the index to that entry
    const numberOfInteractions: u16 = 20000;

    i = 0;
    while (i < numberOfInteractions) : (i += 1) {
        const randomPrisoner1Index: u16 = toInt(std.math.floor(random_float_zero_one() * toFloat(numberOfPrisoners)));
        const randomPrisoner2Index: u16 = toInt(std.math.floor(random_float_zero_one() * toFloat(numberOfPrisoners)));

        // const prisoner1 = prisoners[randomPrisoner1Index];
        // const prisoner2 = prisoners[randomPrisoner2Index];

        std.debug.print("Prisoner 1 {}, Prisoner 2 {}\n", .{ randomPrisoner1Index, randomPrisoner2Index });
    }

    _ = allocator; // Mark allocator as used to avoid warning
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
