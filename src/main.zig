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
        // Arithmetic test:
        1, 10, // 0-1: PUSH 10
        1, 20, // 2-3: PUSH 20
        5, // 4:   ADD (10+20=30)
        14, // 5:   PRINT (prints 30)
        1, 42, // 6-7: PUSH 42
        3, // 8:   DUP (stack becomes [42,42])
        14, // 9:   PRINT (prints 42, stack now [42])
        1, 5, // 10-11: PUSH 5 (stack becomes [42,5])
        7, // 12:  MUL (42*5=210, stack becomes [210])
        14, // 13:  PRINT (prints 210)

        // SWAP test:
        1, 3, // 15-16: PUSH 3
        1, 4, // 17-18: PUSH 4
        4, // 19: SWAP (swap top two values)
        14, // 20: PRINT (prints 3)
        14, // 21: PRINT (prints 4)

        // Loop test (countdown from 3 to 1):
        1, 3, // 22-23: PUSH 3 (counter)
        3, // 24: DUP (duplicate counter)
        14, // 25: PRINT (prints counter)
        1, 1, // 26-27: PUSH 1
        6, // 28: SUB (counter - 1)
        3, // 29: DUP (duplicate new counter)
        1, 22, // 30-31: PUSH 22 (jump target: instruction index 22)
        12, // 32: JNZ (if counter != 0, jump to index 22)
        2, // 33: POP (cleanup leftover 0)

        // PRINT_CHAR test ("Hello World!\n"):
        1, 72, // 34-35: PUSH 72 ('H')
        15, // 36: PRINT_CHAR
        1, 101, // 37-38: PUSH 101 ('e')
        15, // 39: PRINT_CHAR
        1, 108, // 40-41: PUSH 108 ('l')
        15, // 42: PRINT_CHAR
        1, 108, // 43-44: PUSH 108 ('l')
        15, // 45: PRINT_CHAR
        1, 111, // 46-47: PUSH 111 ('o')
        15, // 48: PRINT_CHAR
        1, 32, // 49-50: PUSH 32 (' ')
        15, // 51: PRINT_CHAR
        1, 87, // 52-53: PUSH 87 ('W')
        15, // 54: PRINT_CHAR
        1, 111, // 55-56: PUSH 111 ('o')
        15, // 57: PRINT_CHAR
        1, 114, // 58-59: PUSH 114 ('r')
        15, // 60: PRINT_CHAR
        1, 108, // 61-62: PUSH 108 ('l')
        15, // 63: PRINT_CHAR
        1, 100, // 64-65: PUSH 100 ('d')
        15, // 66: PRINT_CHAR
        1, 33, // 67-68: PUSH 33 ('!')
        15, // 69: PRINT_CHAR
        1, 10, // 70-71: PUSH 10 (newline)
        15, // 72: PRINT_CHAR
        16, // 73: HALT
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
            Opcode.DUP => {
                const byte = try vm.pop();

                vm.push(byte);
                vm.push(byte);
            },
            Opcode.SWAP => {
                const first_byte = try vm.pop();
                const second_byte = try vm.pop();

                vm.push(first_byte);
                vm.push(second_byte);
            },
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

                const difference = second_byte - first_byte;

                vm.push(difference);
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

                const remainder = @rem(second_byte, first_byte);

                vm.push(remainder);
            },
            Opcode.JMP => {
                const jmp_target = try vm.pop();

                // Subtract one to account for the ip++ at the end of the loop
                vm.ip = @as(usize, @intCast(jmp_target)) - 1;
            },
            Opcode.JZ => {
                const jmp_target = try vm.pop();
                const byte = try vm.pop();

                if (byte == 0) {
                    vm.ip = @as(usize, @intCast(jmp_target)) - 1;
                }
            },
            Opcode.JNZ => {
                const jmp_target = try vm.pop();
                const byte = try vm.pop();

                if (byte != 0) {
                    vm.ip = @as(usize, @intCast(jmp_target)) - 1;
                }
            },
            Opcode.NOP => {
                // Intentionally empty - do nothing!
            },
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
