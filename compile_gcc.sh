riscv64-linux-gnu-gcc   -march=rv32i -mabi=ilp32 -O0 t1.s -c
riscv64-linux-gnu-objdump --visualize-jumps=extended-color  --disassembler-color=color -M no-aliases -M numeric -d t1.o 
