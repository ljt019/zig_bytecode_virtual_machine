const std = @import("std");

pub fn main() !void 
{
    const VM = struct {
        allocator: std.mem.Allocator,
        stack: []i32, // explicitly heap-allocated stack
        stack_top: usize, // points to next empty position in stack
        instructions: []u8, // the program
        ip: usize, // instruction pointer (next instruction to run)

        pub fn init() {
            return VM{}
        }

        pub fn deinit(self: *VM) void {
            
        }
    };

    const Opcode = enum {
        PUSH,
        POP,
        ADD,
        SUB,
        MUL,
        DIV,
        PRINT,
        PRINT_CHAR,
        HALT,
    };

    const program = [_]u8{
        1, 5, // PUSH 5
        1, 10, // PUSH 10
        3, // ADD
        7, // PRINT (should print 15)
        8, // HALT
    };

    while(true) {
        switch (instruction) {
            PUSH => unreachable, // read next byte, push onto stack,
            else => unreachable // unknown instruction
        }

        // increment instruction_pointer to next instruction
    }
}
