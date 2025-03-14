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

    /// Push a value onto the stack.
    pub fn push(self: *VM, value: i32) void {
        // Optionally add bounds checking here
        self.stack[self.stack_top] = value;
        self.stack_top += 1;
    }

    /// Pop a value from the stack.
    /// Returns an error if the stack is empty.
    pub fn pop(self: *VM) !i32 {
        if (self.stack_top == 0) {
            return error.StackUnderflow;
        }
        self.stack_top -= 1;
        return self.stack[self.stack_top];
    }
};

const Opcode = enum(u8) {
    // Stack Manipulation:
    PUSH = 1, // Push a value onto the stack
    POP = 2, // Pop a value off the stack
    DUP = 3, // Duplicate the top value
    SWAP = 4, // Swap the two top values

    // Arithmetic Operations:
    ADD = 5, // Add two top values
    SUB = 6, // Subtract two top values
    MUL = 7, // Multiply two top values
    DIV = 8, // Divide two top values
    MOD = 9, // Modulo of two top values

    // Flow Control:
    JMP = 10, // Unconditional jump
    JZ = 11, // Jump if zero
    JNZ = 12, // Jump if not zero
    NOP = 13, // No operation

    // I/O:
    PRINT = 14, // Print a number
    PRINT_CHAR = 15, // Print an ASCII character

    // Stop execution
    HALT = 16,
};

pub fn main() !void {
    var program = [_]u8{
        0, 72, 7, // PUSH 'H', PRINT_CHAR
        0, 101, 7, // PUSH 'e', PRINT_CHAR
        0, 108, 7, // PUSH 'l', PRINT_CHAR
        0, 108, 7, // PUSH 'l', PRINT_CHAR
        0, 111, 7, // PUSH 'o', PRINT_CHAR
        0, 32, 7, // PUSH ' ', PRINT_CHAR
        0, 87, 7, // PUSH 'W', PRINT_CHAR
        0, 111, 7, // PUSH 'o', PRINT_CHAR
        0, 114, 7, // PUSH 'r', PRINT_CHAR
        0, 108, 7, // PUSH 'l', PRINT_CHAR
        0, 100, 7, // PUSH 'd', PRINT_CHAR
        0, 33, 7, // PUSH '!', PRINT_CHAR
        0, 10, 7, // PUSH newline, PRINT_CHAR
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
                vm.push(next_byte);

                // Move the ip forward an extra position to account for the pushed byte
                vm.ip += 1;
            },
            // decrement stack_top
            Opcode.POP => {
                _ = try vm.pop();
            },
            Opcode.DUP => {},
            Opcode.SWAP => {},
            // pop two values, add, push result
            Opcode.ADD => {
                const first_byte = try vm.pop();
                const second_byte = try vm.pop();

                const sum = first_byte + second_byte;

                vm.push(sum);
            },
            // pop two values, subtract, push result
            Opcode.SUB => {
                const first_byte = try vm.pop();
                const second_byte = try vm.pop();

                const difference = first_byte - second_byte;

                vm.stack[vm.stack_top] = difference;

                vm.stack_top += 1;
            },
            Opcode.MUL => {
                const first_byte = try vm.pop();
                const second_byte = try vm.pop();

                const product = first_byte * second_byte;

                vm.push(product);
            },
            // pop two values, divide, push result
            Opcode.DIV => {
                const first_byte = try vm.pop();
                const second_byte = try vm.pop();

                const quotient = @divTrunc(second_byte, first_byte);

                vm.push(quotient);
            },
            Opcode.MOD => {
                const first_byte = try vm.pop();
                const second_byte = try vm.pop();

                const mod = second_byte % first_byte;

                vm.push(mod);
            },
            Opcode.JMP => {},
            Opcode.JZ => {},
            Opcode.JNZ => {},
            Opcode.NOP => {},
            // pop value, print to stdout,
            Opcode.PRINT => {
                const last_byte = try vm.pop();

                std.debug.print("{}\n", .{last_byte});
            },
            // Pops a number from stack; interprets it as ASCII char, prints it
            Opcode.PRINT_CHAR => {
                const char_code = try vm.pop();

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
