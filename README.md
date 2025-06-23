# 🚀 DualPipe-RV32IMZicsr

**DualPipe-RV32IMZicsr** is a high-performance, dual-issue, superscalar, in-order 32-bit RISC-V CPU core based on the RV32IMZicsr ISA. Designed for FPGA and ASIC implementation, configurable branch prediction, CSR handling, MMU functionality, and is fully synthesizable in Verilog-2001.

---

## 🧠 Project Overview

- 🧮 **Architecture**: Dual-issue, 6/7-stage in-order pipeline
- ⚙️ **ISA**: RV32IMZicsr (Integer, Multiply/Divide, CSR)
- 🚀 **Performance**:
  - 2 instructions per cycle max
  - 4.1 CoreMark/MHz
  - 1.9 DMIPS/MHz (337 instr/iteration)
- 🔁 **Pipeline**:
  - 64-bit instruction fetch
  - 32-bit data memory access
  - Dual ALUs + LSU + out-of-pipeline Divider
- 🧠 **Branch Prediction**:
  - Gshare or Bimodal Predictor (configurable)
  - Branch Target Buffer (BTB) + Return Address Stack (RAS)
- 🔐 **Privilege Support**: User, Supervisor, Machine
- 💻 **MMU**: SV32 translation, Linux boot capable (atomics via emulation)
- 📦 **Interfaces**: AXI4 / TCM (configurable)
- ✅ **Verification**:
  - Google RISCV-DV
  - Co-simulation with C++ ISA model
  - CoreMark / Dhrystone / Linux boot

---

## 📁 Directory Structure
DualPipe-RV32IMZicsr/
├── src/ # RTL Modules (Verilog 2001)
│ ├── fetch/ # Instruction Fetch and PC logic
│ ├── decode/ # Dual-instruction decoder, reg file
│ ├── issue/ # Hazard detection, issue arbiter
│ ├── execute/ # ALU, branch, divider
│ ├── memory/ # Load/Store Unit (LSU)
│ ├── csr/ # CSR file, trap/exception logic
│ ├── mmu/ # MMU and SV32 page translation
│ └── top/ # Core integration logic
├── tb/ # Testbenches (Verilator/SystemVerilog)
├── sim/ # Build/test automation (Makefiles/scripts)
├── fpga/ # Synthesis files for FPGA boards
├── docs/ # Block diagrams, flowcharts, specs
├── scripts/ # Helper scripts for sim/test
├── PLANNING.md # Daily development schedule
└── README.md # Project overview (this file)


---

## 📅 2-Week Development Plan

This project follows a **one-module-per-day** agile structure:

| **Date**   | **Day** | **Module / Task**       | **Description**                             |
| ---------- | ------: | ----------------------- | ------------------------------------------- |
| 2025-06-23 |   Day 1 | Architecture Planning   | Define pipeline layout, datapaths           |
| 2025-06-24 |   Day 2 | PC Logic                | Program Counter update & branch redirection |
| 2025-06-25 |   Day 3 | Instruction Fetch       | 64-bit fetch, memory alignment              |
| 2025-06-26 |   Day 4 | Decode + Register File  | Decode 2 instructions, reg read             |
| 2025-06-27 |   Day 5 | Issue Unit              | Hazard checks, resource arbitration         |
| 2025-06-28 |   Day 6 | ALUs (x2)               | Arithmetic, shift, comparison ops           |
| 2025-06-29 |   Day 7 | Branch + Predictor      | Gshare/Bimodal predictor, BTB, RAS          |
| 2025-06-30 |   Day 8 | Load/Store Unit         | LSU with alignment and byte masking         |
| 2025-07-01 |   Day 9 | Divider Unit            | Out-of-pipeline handshake divider           |
| 2025-07-02 |  Day 10 | CSR Unit                | Zicsr support: `mstatus`, `mtvec`, etc.     |
| 2025-07-03 |  Day 11 | MMU                     | SV32 MMU, TLB, `satp`, exception hooks      |
| 2025-07-04 |  Day 12 | Forwarding & Stalling   | Bypass network + inter-instr dependencies   |
| 2025-07-05 |  Day 13 | Testbenches (Verilator) | Unit/integration tests, waveforms           |
| 2025-07-06 |  Day 14 | Linux Boot Integration  | Load ELF, debug boot log                    |


---

## 🛠️ Build Instructions

### 🔧 Prerequisites
- Verilator (v5.0+)
- GTKWave
- Python 3.x

### 🔨 Build & Run

```bash
# Clone the repository
git clone https://github.com/hilay0200905/RV32IMZicsr.git
cd RV32IMZicsr
