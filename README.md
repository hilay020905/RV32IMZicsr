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
The Verilog code implements a branch prediction system for a processor, using a Branch Target Buffer (BTB) to store branch addresses and predict targets, a Branch History Table (BHT) with 2-bit saturating counters for taken/not-taken predictions, and a Return Address Stack (RAS) for handling call/return instructions. It supports configurable features like GShare indexing and uses an LFSR for random BTB entry allocation on misses. The system predicts the next program counter (PC) and branch outcome based on speculative and actual branch history, improving fetch stage efficiency. An LFSR (Linear Feedback Shift Register) is a shift register whose input bit is a linear function of its previous state, typically implemented using XOR operations with specific bits (taps). In the provided NEXT_PC_LFSR module, it generates a pseudo-random sequence for BTB entry allocation. The LFSR shifts its 16-bit state (lfsr_q) right, feeding back an XOR of selected bits (based on TAP_VALUE) when the LSB is 1, ensuring a random index (alloc_entry_o) for replacing BTB entries on misses.



### 🔧 Prerequisites
- iVerilog
- GTKWave


### 🔨 Build & Run

```bash
# Clone the repository
git clone https://github.com/hilay0200905/RV32IMZicsr.git
cd RV32IMZicsr
