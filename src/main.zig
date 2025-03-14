const std = @import("std");

const VM = struct {
    allocator: std.mem.Allocator,
    stack: []i32, // explicitly heap-allocated stack
    stack_top: usize, // points to next empty position in stack
    instructions: []u8, // the program
    ip: usize, // instruction pointer (next instruction to run)

    pub fn init(instructions: []u8) !VM {
        // create the allocateor and allocate space for 1024 i32 elements
        const allocator = std.heap.page_allocator;
        const stack = try allocator.alloc(i32, 1024);

        return VM{
            .allocator = allocator,
            .stack = stack,
            .stack_top = 0,
            .instructions = instructions,
            .ip = 0,
        };
    }

    pub fn deinit(self: *VM) void {
        self.allocator.free(self.stack);
    }

    pub fn load_program(self: *VM, program: []u8) void {
        self.instructions = program;
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

pub fn main() !void {
    var program = [_]u8{
        0, 72, 7, // PUSH 'H' (ASCII 72), PRINT_CHAR
        0, 101, 7, // PUSH 'e' (ASCII 101), PRINT_CHAR
        0, 108, 7, // PUSH 'l', PRINT_CHAR
        0, 108, 7, // PUSH 'l', PRINT_CHAR
        0, 111, 7, // PUSH 'o', PRINT_CHAR
        0, 32, 7, // PUSH ' ', PRINT_CHAR
        0, 87, 7, // PUSH 'W', PRINT_CHAR
        0, 111, 7, // PUSH 'o', PRINT_CHAR
        0, 114, 7, // PUSH 'r', PRINT_CHAR
        0, 108, 7, // PUSH 'l', PRINT_CHAR
        0, 100, 7, // PUSH 'd', PRINT_CHAR
        0, 10, 7, // PUSH newline (ASCII 10), PRINT_CHAR
        8, // HALT
    };

    var vm = try VM.init(&program);

    while (true) {
        const instruction = std.meta.intToEnum(Opcode, vm.instructions[vm.ip]) catch {
            std.debug.print("Invalid opcode: {}\n", .{vm.instructions[vm.ip]});
            return;
        };

        switch (instruction) {
            Opcode.PUSH => {
                // read next byte
                const next_byte = vm.instructions[vm.ip + 1];

                // Push the next_byte onto the stack
                vm.stack[vm.stack_top] = next_byte;
                vm.stack_top += 1;

                // Move the ip forward an extra position to account for the pushed byte
                vm.ip += 1;
            },
            // decrement stack_top
            Opcode.POP => {
                if (vm.stack_top == 0) {
                    std.debug.print("Stack underflow error\n", .{});
                    return;
                }

                vm.stack_top -= 1;
            },
            // pop two values, add, push result
            Opcode.ADD => {
                if (vm.stack_top < 2) {
                    std.debug.print("Stack underflow error (ADD needs 2 operands)\n", .{});
                    return;
                }

                vm.stack_top -= 1;
                const first_byte = vm.stack[vm.stack_top];

                vm.stack_top -= 1;
                const second_byte = vm.stack[vm.stack_top];

                const sum = first_byte + second_byte;

                vm.stack[vm.stack_top] = sum;

                vm.stack_top += 1;
            },
            // pop two values, subtract, push result
            Opcode.SUB => {
                if (vm.stack_top < 2) {
                    std.debug.print("Stack underflow error (SUB needs 2 operands)\n", .{});
                    return;
                }

                vm.stack_top -= 1;
                const first_byte = vm.stack[vm.stack_top];

                vm.stack_top -= 1;
                const second_byte = vm.stack[vm.stack_top];

                const difference = first_byte - second_byte;

                vm.stack[vm.stack_top] = difference;

                vm.stack_top += 1;
            },
            Opcode.MUL => {
                if (vm.stack_top < 2) {
                    std.debug.print("Stack underflow error (MUL needs 2 operands)\n", .{});
                    return;
                }

                vm.stack_top -= 1;
                const first_byte = vm.stack[vm.stack_top];

                vm.stack_top -= 1;
                const second_byte = vm.stack[vm.stack_top];

                const product = first_byte * second_byte;

                vm.stack[vm.stack_top] = product;

                vm.stack_top += 1;
            },
            // pop two values, divide, push result
            Opcode.DIV => {
                if (vm.stack_top < 2) {
                    std.debug.print("Stack underflow error (DIV needs 2 operands)\n", .{});
                    return;
                }

                vm.stack_top -= 1;
                const first_byte = vm.stack[vm.stack_top];

                vm.stack_top -= 1;
                const second_byte = vm.stack[vm.stack_top];

                const quotient = @divTrunc(second_byte, first_byte);

                vm.stack[vm.stack_top] = quotient;

                vm.stack_top += 1;
            },
            // pop value, print to stdout,
            Opcode.PRINT => {
                vm.stack_top -= 1;

                const last_byte = vm.stack[vm.stack_top];

                std.debug.print("{}\n", .{last_byte});
            },
            // Pops a number from stack; interprets it as ASCII char, prints it
            Opcode.PRINT_CHAR => {
                if (vm.stack_top == 0) {
                    std.debug.print("Stack underflow error (PRINT_CHAR needs 1 operand)\n", .{});
                    return;
                }

                vm.stack_top -= 1;
                const char_code = vm.stack[vm.stack_top];
                std.debug.print("{c}", .{@as(u8, @intCast(char_code))});
            },
            // break loop (VM execution ends),
            Opcode.HALT => {
                break;
            },
        }

        // increment instruction_pointer to next instruction
        vm.ip += 1;
    }

    vm.deinit();
}
