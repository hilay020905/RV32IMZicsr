# 🚀 DUAL-CORE-RV32IMZicsr
**PREVIOUS**: https://github.com/hilay020905/RISC_V_CORE

**DUAL-CORE-RV32IMZicsr** is a high-performance, dual-issue, superscalar, in-order 32-bit RISC-V CPU core based on the RV32IMZicsr ISA. Designed for configurable branch prediction, CSR handling, and is fully synthesizable in Verilog-2001.

---

## 🧠 Project Overview

- 🧮 **Architecture**: Dual-issue, 7-stage in-order pipeline
- ⚙️ **ISA**: RV32IMZicsr (Integer, Multiply/Divide, CSR)
- 🚀 **Performance**:
  - 2 instructions per cycle max
- 🔁 **Pipeline**:
  - 64-bit instruction fetch
  - 32-bit data memory access
  - Dual ALUs + LSU + out-of-pipeline Divider
- 🧠 **Branch Prediction**:
  - Gshare or Bimodal Predictor (configurable)
  - Branch Target Buffer (BTB) + Return Address Stack (RAS)


---

# 📅 2-Week Development Plan

| **Date**   | **Day** | **Module / Task**       | 
| ---------- | ------: | ----------------------- | 
| 2025-06-23 |   Day 1 | Architecture Planning   | 
| 2025-06-24 |   Day 2 | Next PC Logic           | 
| 2025-06-25 |   Day 3 | Fetch unit              | 
| 2025-06-26 |   Day 4 | Decode unit + Decoder   | 
| 2025-06-27 |   Day 5 | Issue Unit              |
| 2025-06-28 |   Day 6 | ALUs (x2)               |
| 2025-06-29 |   Day 7 | Branch + Predictor      | 
| 2025-06-30 |   Day 8 | Load/Store Unit         | 
| 2025-07-01 |   Day 9 | Divider Unit            | 
| 2025-07-02 |  Day 10 | CSR Unit                | 
| 2025-07-03 |  Day 11 | MMU                     | 
| 2025-07-04 |  Day 12 | Forwarding & Stalling   | 
| 2025-07-05 |  Day 13 | Testbenches (Verilator) | 

## Architecture Planning
![Processor Architecture](IMAGES/FIG01.png)

# Microarchitecture
## NEXT PC LOGIC (Configurable with or without branch prediction)

This module evaluates the **Next Program Counter (PC) Prediction** unit for a RISC-V CPU with branch prediction support using:

- **BTB** (Branch Target Buffer) Remembers where a branch instruction goes (target address). Used to predict the destination of jumps, calls, and branches.
- **BHT** (Branch History Table) Predicts whether a branch is taken or not taken. Uses past behavior to guide future predictions.
- **RAS** (Return Address Stack) Predicts return addresses for function returns (ret). Stores return PCs from call instructions in a stack-like structure.

![TESTBENCHES](IMAGES/FIG02(A).png)

![TESTBENCHES](IMAGES/FIG02(B).png)


| Test Case | Inputs Activated                                                 | Output PC (`next_pc_f_o`) | Prediction (`next_taken_f_o`) | Explanation                                                |
| --------- | ---------------------------------------------------------------- | ------------------------- | ----------------------------- | ---------------------------------------------------------- |
| 1         | None                                                             | `00001008`                | `00`                          | Sequential fetch (`pc + 8`), no BTB prediction.            |
| 2         | `branch_request_i`, `branch_is_taken_i`                          | Updates BTB               | `00`                          | Real branch taken, updates BTB for next predictions.       |
| 3         | `pc_accept_i`                                                    | `00002000`                | `01`                          | BTB predicts branch from Test 2, correct prediction.       |
| 4         | `branch_request_i`, `branch_is_call_i`                           | Updates RAS               | `01`                          | Function call, pushes return address to RAS.               |
| 5         | `branch_request_i`, `branch_is_ret_i`                            | `00002000`                | `01`                          | Return predicted using RAS stack (correctly).              |
| 6         | `branch_request_i`, `branch_is_not_taken_i`                      | Updates BHT               | `01`                          | Not-taken branch trains BHT to avoid future mispredict.    |
| 7         | `branch_request_i`, `branch_is_jmp_i`                            | Updates BTB               | `01`                          | Jump instruction predicted by BTB.                         |
| 8         | `invalidate_i` pulse                                             | `00002000`                | `01`                          | Prediction structures invalidated; no visible change.      |
| 9         | `branch_request_i`, `branch_is_taken_i`, `branch_is_not_taken_i` | `00002000`                | `01`                          | Simulates dual branch behavior (both taken and not taken). |
| 10        | None                                                             | `00002000`                | `01`                          | Idle, no new input activity.                               |

## Fetch unit
The FETCH module implements the instruction fetch stage of a processor, handling program counter management, branch requests, and instruction cache interactions. It supports optional MMU functionality and manages stalls, faults, and backpressure using a skid buffer.

![FETCH UNIT](IMAGES/FIG03.jpg)

| **Group**           | **Signal Name**            | **Purpose / Notes**                                 | 
| ------------------- | -------------------------- | --------------------------------------------------- | 
| ⏱️ Clock & Reset    | `clk_i`                    | Main system clock (10ns period)                     | 
|                     | `rst_i`                    | Active-high reset signal                            | 
| ▶️ Input Control    | `fetch_accept_i`           | Downstream fetch unit ready                         | 
|                     | `icache_accept_i`          | Instruction cache accepts read request              | 
|                     | `icache_valid_i`           | Valid instruction data from cache                   | 
|                     | `branch_request_i`         | Trigger branch fetch                                | 
|                     | `fetch_invalidate_i`       | Invalidate fetch (for flushes)                      | 
|                     | `icache_error_i`           | Cache returned error                                | 
|                     | `icache_page_fault_i`      | Cache reported page fault                           | 
| ✅ Output           | `fetch_valid_o`            | Instruction output is valid                         | 
|                     | `fetch_pred_branch_o[1:0]` | Predicted branch decision                           | 
|                     | `fetch_fault_fetch_o`      | Fetch fault (e.g., alignment)                       | 
|                     | `fetch_fault_page_o`       | Page fault occurred during fetch                    | 
|                     | `icache_priv_o[1:0]`       | Privilege level sent to I-cache                     | 
| 🧠 Internal Signals | `active_q`                 | Indicates if fetch stage is active                  |
|                     | `branch_q`                 | Branch state active                                 | 
|                     | `stall_q`                  | Indicates if fetch stage is stalled                 | 
|                     | `skid_valid_q`             | Skid buffer has valid data                          | 

![TESTBENCHES](IMAGES/FIG04.png)

## Decode unit

![Processor Architecture](IMAGES/FIG05.jpg)

| **Signal Name**               | **Role**                         | **Importance for Analysis**                                                            |
| ----------------------------- | -------------------------------- | -------------------------------------------------------------------------------------- |
| `fetch_in_valid_i`            | Input Control - Input Valid      | High when instruction pair is valid (e.g., 20 ns, 50 ns); initiates FIFO push.         |
| `fetch_in_accept_o`           | Output Control - Input Accept    | High when FIFO can accept new instructions; confirms buffer availability.              |
| `fetch_out0_valid_o`          | Output Control - Channel 0 Valid | High when channel 0 has a valid instruction (e.g., \~30 ns); signals downstream stage. |
| `fetch_out1_valid_o`          | Output Control - Channel 1 Valid | High when channel 1 has a valid instruction; important for dual-issue pipelines.       |
| `fetch_out0_accept_i`         | Input Control - Channel 0 Accept | High when downstream logic consumes channel 0 instruction; affects FIFO pop.           |
| `fetch_out1_accept_i`         | Input Control - Channel 1 Accept | High when downstream logic consumes channel 1 instruction.                             |
| `fetch_in_instr_i[63:0]`      | Input - Instruction Pair         | Contains 2x32-bit instructions; analyzed to verify opcodes (e.g., `LW`, `ADDI`).       |
| `fetch_in_pc_i[31:0]`         | Input - Program Counter          | Aligned base PC (e.g., `0x1000`); helps validate correct PC tracking.                  |
| `fetch_in_pred_branch_i[1:0]` | Input - Predicted Branch         | Indicates expected control flow path (affects output channel validity).                |
| `fetch_in_fault_fetch_i`      | Input - Fetch Fault              | High triggers fault handling logic (e.g., Test 5); propagates to CSR/fault status.     |
| `fetch_in_fault_page_i`       | Input - Page Fault               | Monitors memory page access errors; reserved for fault management.                     |
| `branch_request_i`            | Input - Branch Request           | High flushes the FIFO (e.g., at 170 ns in Test 6); ensures pipeline redirection.       |
| `branch_pc_i[31:0]`           | Input - Branch PC                | New target address on branch (e.g., `0x2000`); used to restart fetch.                  |
| `branch_priv_i[1:0]`          | Input - Branch Privilege         | Indicates privilege level (e.g., machine mode); required for CSR/memory access.        |

🔀 Output: Channel 0
| **Signal**                    | **Role**             | **Importance**                                              |
| ----------------------------- | -------------------- | ----------------------------------------------------------- |
| `fetch_out0_instr_o[31:0]`    | Instruction          | Contains decoded instruction (e.g., `0x00100093` = `ADDI`). |
| `fetch_out0_pc_o[31:0]`       | Program Counter      | PC of channel 0 instruction (e.g., `0x1000`).               |
| `fetch_out0_instr_exec_o`     | ALU Operation        | High for arithmetic/logic ops (e.g., `ADDI`).               |
| `fetch_out0_instr_lsu_o`      | Load/Store Operation | High for memory ops (e.g., `LW`).                           |
| `fetch_out0_instr_branch_o`   | Branch Operation     | High if instruction is `JAL`, `BEQ`, etc.                   |
| `fetch_out0_instr_mul_o`      | Multiplication       | High when `MUL` detected (Test 3).                          |
| `fetch_out0_instr_div_o`      | Division             | High if `DIV` detected (monitored only).                    |
| `fetch_out0_instr_csr_o`      | CSR/System Operation | High for `CSRRW`, `CSRRS`, or fault-based system ops.       |
| `fetch_out0_instr_rd_valid_o` | Register Write       | High if instruction writes to `rd` (e.g., `ADDI`, `JAL`).   |
| `fetch_out0_instr_invalid_o`  | Invalid Instruction  | High for illegal encodings (e.g., `0xFFFFFFFF` in Test 4).  |
| `fetch_out0_fault_fetch_o`    | Fetch Fault          | Indicates instruction fetch fault propagated.               |
| `fetch_out0_fault_page_o`     | Page Fault           | Page-level fault status (monitored only).                   |

🔀 Output: Channel 1
| **Signal**                    | **Role**             | **Importance**                                   |
| ----------------------------- | -------------------- | ------------------------------------------------ |
| `fetch_out1_instr_o[31:0]`    | Instruction          | Decoded instruction (e.g., `0x00020083` = `LW`). |
| `fetch_out1_pc_o[31:0]`       | Program Counter      | PC of channel 1 instruction (e.g., `0x1004`).    |
| `fetch_out1_instr_exec_o`     | ALU Operation        | ALU instruction decoder flag (e.g., `ADDI`).     |
| `fetch_out1_instr_lsu_o`      | Load/Store Operation | High for `LW`, `SW`, etc.                        |
| `fetch_out1_instr_branch_o`   | Branch Operation     | High if branch (`BEQ`) present.                  |
| `fetch_out1_instr_mul_o`      | Multiplication       | Monitored (not tested).                          |
| `fetch_out1_instr_div_o`      | Division             | Monitored (not tested).                          |
| `fetch_out1_instr_csr_o`      | CSR/System Operation | High on `CSR` instructions or faults.            |
| `fetch_out1_instr_rd_valid_o` | Register Write       | High if `rd` is written.                         |
| `fetch_out1_instr_invalid_o`  | Invalid Instruction  | Illegal opcodes (if present).                    |
| `fetch_out1_fault_fetch_o`    | Fetch Fault          | Fault detected on fetch for channel 1.           |
| `fetch_out1_fault_page_o`     | Page Fault           | Memory page fault flag (monitored).              |


The testbench includes **six unit tests**, each targeting specific decode logic behavior:

### ✅ Test Cases:

1. **Test 1 – Valid Instructions**
   - Inputs: `ADDI` and `LW`
   - ✅ Tests ALU and load/store decoding logic.

2. **Test 2 – Branch Instruction with Prediction**
   - Input: `JAL` with predicted branch
   - ✅ Tests branch decoding and prediction path handling.

3. **Test 3 – Multiply Instruction**
   - Input: `MUL` (requires `SUPPORT_MULDIV = 1`)
   - ✅ Validates MULDIV instruction decoding.

4. **Test 4 – Invalid Instruction**
   - Input: `0xFFFFFFFF`
   - ✅ Detects illegal instructions; sets invalid flag.

5. **Test 5 – Fetch Fault**
   - Condition: `fetch_fault` set high
   - ✅ Verifies fault handling and propagation logic.

6. **Test 6 – Branch Flush & CSR**
   - Sequence: `branch_request_i`, then `CSRRW` and `BEQ`
   - ✅ Tests pipeline flush behavior, CSR, and branch decode after redirection.

![TESTBENCHES](IMAGES/FIG06.png)


### 🔧 Prerequisites
- iVerilog
- GTKWave


### 🔨 Build & Run

```bash
# Clone the repository
git clone https://github.com/hilay0200905/RV32IMZicsr.git
cd RV32IMZicsr
