import java.lang { BooleanArray, IntArray }

class Machine(IntArray rom, Peripherals peripherals) {
    IntArray mem = IntArray(#1000, 0);
    IntArray regs = IntArray(#10, 0);
    IntArray stack = IntArray(#10, 0);
    BooleanArray grahpics = BooleanArray(screenWidth * screenHeight, false);
    BooleanArray keys = BooleanArray(#10, false);
    variable Integer pc = #200;
    variable Integer addr = 0;
    variable Integer pointer = 0;
    variable Integer delay = 0;
    variable Integer sound = 0;

    void copy(Integer start, Integer* source) {
        variable Integer i = start;

        for (b in source) {
            mem[i++] = b.and(#ff);
        }
    }

    copy(0, *glyphs*.leftLogicalShift(4));
    copy(pc, *rom);

    shared Boolean getPixel(Integer x, Integer y) => grahpics[y * screenWidth + x];

    shared Boolean isKeyPressed(Integer x) => keys[x];

    shared void setKeyPressed(Integer x, Boolean pressed) => keys[x] = pressed;

    shared void cycle() {
        value opcode = mem[pc].leftLogicalShift(8).or(mem[pc + 1]);

        if (execute(opcode)) {
            pc += 2;
        }

        if (sound > 0) {
            peripherals.beep();
            sound--;
        }

        if (delay > 0) {
            delay--;
        }
    }

    Boolean execute(Integer opcode) {
        variable Boolean increment = true;
        value n0 = opcode.rightLogicalShift(12).and(#f);
        value n1 = opcode.rightLogicalShift(8).and(#f);
        value n2 = opcode.rightLogicalShift(4).and(#f);
        value n3 = opcode.and(#f);

        if (opcode == #00e0) {
            for (index in 0:grahpics.size) {
                grahpics[index] = false;
            }
        }
        else if (opcode == #00ee) {
            pc = stack[--pointer];
        }
        else if (n0 == 1) {
            pc = opcode.and(#0fff);
            increment = false;
        }
        else if (n0 == 2) {
            stack[pointer++] = pc;
            pc = opcode.and(#0fff);
            increment = false;
        }
        else if (n0 == 3) {
            if (regs[n1] == opcode.and(#00ff)) {
                pc += 2;
            }
        }
        else if (n0 == 4) {
            if (regs[n1] != opcode.and(#00ff)) {
                pc += 2;
            }
        }
        else if (n0 == 5) {
            if (regs[n1] == regs[n2]) {
                pc += 2;
            }
        }
        else if (n0 == 6) {
            regs[n1] = opcode.and(#00ff);
        }
        else if (n0 == 7) {
            regs[n1] = (regs[n1] + opcode.and(#00ff)).and(#ff);
        }
        else if (opcode.and(#f00f) == #8000) {
            regs[n1] = regs[n2];
        }
        else if (opcode.and(#f00f) == #8001) {
            regs[n1] = regs[n1].or(regs[n2]);
        }
        else if (opcode.and(#f00f) == #8002) {
            regs[n1] = regs[n1].and(regs[n2]);
        }
        else if (opcode.and(#f00f) == #8003) {
            regs[n1] = regs[n1].xor(regs[n2]);
        }
        else if (opcode.and(#f00f) == #8004) {
            value total = regs[n1] + regs[n2];
            regs[n1] = total.and(#ff);
            regs[#f] = if (total > #ff) then 1 else 0;
        }
        else if (opcode.and(#f00f) == #8005) {
            value total = regs[n1] - regs[n2];
            regs[n1] = total.and(#ff);
            regs[#f] = if (total < 0) then 1 else 0;
        }
        else if (opcode.and(#f00f) == #8006) {
            value original = regs[n1];
            regs[n1] = original.rightLogicalShift(1).and(#ff);
            regs[#f] = original.and(#01);
        }
        else if (opcode.and(#f00f) == #8007) {
            value total = regs[n2] - regs[n1];
            regs[n1] = total.and(#ff);
            regs[#f] = if (total < 0) then 1 else 0;
        }
        else if (opcode.and(#f00f) == #800e) {
            value original = regs[n1];
            regs[n1] = original.leftLogicalShift(1).and(#ff);
            regs[#f] = original.rightLogicalShift(7).and(#01);
        }
        else if (n0 == 9) {
            if (regs[n1] != regs[n2]) {
                pc += 2;
            }
        }
        else if (n0 == #a) {
            addr = opcode.and(#0fff);
        }
        else if (n0 == #b) {
            pc = regs[0] + opcode.and(#0fff);
            increment = false;
        }
        else if (n0 == #c) {
            value mask = opcode.and(#00ff);
            regs[n1] = peripherals.rand().and(mask);
        }
        else if (n0 == #d) {
            value x = regs[n1];
            value y = regs[n2];
            variable Boolean unset = false;

            for (dy in 0:n3) {
                value line = mem[addr + dy];

                for (dx in 0:8) {
                    value index = ((y + dy) % screenHeight) * screenWidth + ((x + dx) % screenWidth);

                    if (line.rightLogicalShift(7 - dx).and(#01) != 0) {
                        unset ||= grahpics[index];
                        grahpics[index] = !grahpics[index];
                    }
                }
            }

            regs[#f] = if (unset) then 1 else 0;
        }
        else if (opcode.and(#f0ff) == #e09e) {
            if (keys.get(n1)) {
                pc += 2;
            }
        }
        else if (opcode.and(#f0ff) == #e0a1) {
            if (!keys.get(n1)) {
                pc += 2;
            }
        }
        else if (opcode.and(#f0ff) == #f007) {
            regs[n1] = delay;
        }
        else if (opcode.and(#f0ff) == #f00a) {
            regs[n1] = peripherals.waitForKeyPressed();
        }
        else if (opcode.and(#f0ff) == #f015) {
            delay = regs[n1];
        }
        else if (opcode.and(#f0ff) == #f018) {
            sound = regs[n1];
        }
        else if (opcode.and(#f0ff) == #f01e) {
            addr += regs[n1];
            regs[#f] = if (addr > #0fff) then 1 else 0;
        }
        else if (opcode.and(#f0ff) == #f029) {
            addr = regs[n1] * glyphWidth;
        }
        else if (opcode.and(#f0ff) == #f033) {
            value x = regs[n1];
            mem[addr] = x / 100 % 10;
            mem[addr + 1] = x / 10 % 10;
            mem[addr + 2] = x % 10;
        }
        else if (opcode.and(#f0ff) == #f055) {
            for (i in 0:(n1 + 1)) {
                mem[addr + i] = regs[i];
            }

            addr = (addr + n1 + 1).and(#ffff);
        }
        else if (opcode.and(#f0ff) == #f065) {
            for (i in 0:(n1 + 1)) {
                regs[i] = mem[addr + i];
            }

            addr = (addr + n1 + 1).and(#ffff);
        }
        else {
            throw Exception("Invalid opcode: ``hex(opcode)``");
        }

        return increment;
    }
}
