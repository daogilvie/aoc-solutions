const std = @import("std");

const compstr = *const [14:0]u8;

const daycount = 21;

const days: [daycount]compstr = blk: {
    var days_inner: [daycount]compstr = undefined;
    inline for (0..daycount) |day| {
        const day_str = std.fmt.comptimePrint("day{0d:0>2}/main.zig", .{day + 1});
        days_inner[day] = day_str;
    }
    break :blk days_inner;
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    var step_name_buffer = [6]u8{ 't', 'e', 's', 't', '0', '0' };

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Add the shared utils module
    const aocutils = b.createModule(.{ .source_file = std.Build.FileSource{ .path = "./aocutils.zig" } });

    const cwd = std.fs.cwd();

    // Similar to creating the run step, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const global_test_step = b.step("test", "Run unit tests");

    for (days) |day| {
        const day_exists = cwd.access(day[3..5], .{});

        if (day_exists) |_| {
            const exe = b.addExecutable(.{
                .name = day[0..5],
                // In this case the main source file is merely a path, however, in more
                // complicated build scripts, this could be a generated file.
                .root_source_file = .{ .path = day[3..] },
                .target = target,
                .optimize = optimize,
            });

            exe.addModule("aocutils", aocutils);

            // This declares intent for the executable to be installed into the
            // standard location when the user invokes the "install" step (the default
            // step when running `zig build`).
            b.installArtifact(exe);

            // Creates a step for unit testing. This only builds the test executable
            // but does not run it.
            const unit_tests = b.addTest(.{
                .root_source_file = .{ .path = day[3..] },
                .target = target,
                .optimize = optimize,
            });
            unit_tests.addModule("aocutils", aocutils);

            const run_unit_tests = b.addRunArtifact(unit_tests);

            step_name_buffer[4] = day[3];
            step_name_buffer[5] = day[4];

            const day_test_step = b.step(step_name_buffer[0..6], "Run tests for this day");
            day_test_step.dependOn(&run_unit_tests.step);

            global_test_step.dependOn(&run_unit_tests.step);

            // These build declarations add a dayXX target that runs each day
            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }
            const run_step = b.step(day[0..5], "Run the puzzle for this day");
            run_step.dependOn(&run_cmd.step);
        } else |_| {}
    }
}
