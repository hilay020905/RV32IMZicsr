# 🚀 DualPipe-RV32IMZicsr
**PREVIOUS**: https://github.com/hilay020905/RISC_V_CORE

**DualPipe-RV32IMZicsr** is a high-performance, dual-issue, superscalar, in-order 32-bit RISC-V CPU core based on the RV32IMZicsr ISA. Designed for configurable branch prediction, CSR handling, and is fully synthesizable in Verilog-2001.

---

## 🧠 Project Overview

- 🧮 **Architecture**: Dual-issue, 6/7-stage in-order pipeline
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

## 📅 2-Week Development Plan

| **Date**   | **Day** | **Module / Task**       | 
| ---------- | ------: | ----------------------- | 
| 2025-06-23 |   Day 1 | Architecture Planning   | 
| 2025-06-24 |   Day 2 | NEXT PC Logic           | 
| 2025-06-25 |   Day 3 | Instruction Fetch       | 
| 2025-06-26 |   Day 4 | Decode + Register File  | 
| 2025-06-27 |   Day 5 | Issue Unit              |
| 2025-06-28 |   Day 6 | ALUs (x2)               |
| 2025-06-29 |   Day 7 | Branch + Predictor      | 
| 2025-06-30 |   Day 8 | Load/Store Unit         | 
| 2025-07-01 |   Day 9 | Divider Unit            | 
| 2025-07-02 |  Day 10 | CSR Unit                | 
| 2025-07-03 |  Day 11 | MMU                     | 
| 2025-07-04 |  Day 12 | Forwarding & Stalling   | 
| 2025-07-05 |  Day 13 | Testbenches (Verilator) | 

## DAY 1: Architecture Planning
![Processor Architecture](IMAGES/FIG1.png)

---
# Microarchitecture
## DAY 2: NEXT PC LOGIC 
The Verilog code implements a branch prediction system for a processor, using a Branch Target Buffer (BTB) to store branch addresses and predict targets, a Branch History Table (BHT) with 2-bit saturating counters for taken/not-taken predictions, and a Return Address Stack (RAS) for handling call/return instructions. It supports configurable features like GShare indexing and uses an LFSR for random BTB entry allocation on misses. The system predicts the next program counter (PC) and branch outcome based on speculative and actual branch history, improving fetch stage efficiency.


| **Signal**              | **Description**                               | **Key Transitions and Values**                                                                                     | **Observations**                                                      |
| ----------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- |
| `invalidate_i`          | Invalidates predictions                       | Brief high pulse \~170–180 ns (Test Case 8)                                                                        | Temporary assertion; no visible impact on outputs.                    |
| `branch_request_i`      | Branch resolution event                       | High pulses at \~50–60 ns, \~90–100 ns, \~110–120 ns, \~130–140 ns, \~150–160 ns, \~190–200 ns                     | Corresponds to Test Cases 2, 4, 5, 6, 7, and 9 (branch events).       |
| `branch_is_taken_i`     | Branch was taken                              | High at \~50–60 ns (Test Case 2), \~190–200 ns (first branch of Test Case 9)                                       | Indicates taken branches.                                             |
| `branch_is_not_taken_i` | Branch was not taken                          | High at \~130–140 ns (Test Case 6), \~190–200 ns (second branch of Test Case 9)                                    | Indicates not-taken branches.                                         |
| `branch_is_call_i`      | CALL instruction detected                     | High at \~90–100 ns (Test Case 4)                                                                                  | Indicates subroutine CALL (push return address to RAS).               |
| `branch_is_ret_i`       | RETURN instruction detected                   | High at \~110–120 ns (Test Case 5)                                                                                 | Indicates subroutine RETURN (pop address from RAS).                   |
| `branch_is_jmp_i`       | JUMP instruction detected                     | High at \~150–160 ns (Test Case 7)                                                                                 | Indicates unconditional JUMP.                                         |
| `next_pc_f_o[31:0]`     | Predicted next PC                             | `00001008` (\~30–50 ns, Test Case 1), `00002000` (\~70–90 ns, Test Case 3), `00001014` (\~110–130 ns, Test Case 5) | Changes reflect PC+8 (sequential), BTB hit, or RAS-based predictions. |
| `next_taken_f_o[1:0]`   | Prediction result: 00 (not taken), 01 (taken) | 00 (\~30–50 ns), 01 (\~70–90 ns, Test Case 3), 01 (\~110–130 ns, Test Case 5)                                      | "00" = default linear flow, "01" = predicted-taken from BTB or RAS.   |



### 🔧 Prerequisites
- iVerilog
- GTKWave


### 🔨 Build & Run

```bash
# Clone the repository
git clone https://github.com/hilay0200905/RV32IMZicsr.git
cd RV32IMZicsr
