# FPGA-Based Systolic Array Processor


A high-performance **systolic array accelerator** implemented on an FPGA, featuring a 2×2 processing element grid for parallel matrix computations and digital signal processing operations. This project demonstrates advanced hardware design patterns, spatial parallelism, and real-time I/O interfacing on Xilinx FPGAs.

## 🎯 Features

- **Systolic Architecture**: 2×2 grid of processing elements with tightly-coupled data flow
- **Spatial Parallelism**: Simultaneous computation across multiple data elements
- **Real-Time I/O**:
  - 16 software-controlled input switches
  - 16 LED status indicators
  - Dual 7-segment display outputs for result visualisation
  - Push-button interface for control and reset
- **32-bit Accumulation**: Enhanced precision with 16-bit input and 32-bit output
- **Debounced Control**: Robust mechanical switch debouncing and edge detection
- **100 MHz Operation**: High-performance clock domain with synchronous design

## 📋 Project Overview

The **Systolic Bleh** project implements a dataflow-optimised parallel processing architecture on FPGA hardware. Systolic arrays are specialised architectures where:

- **Data flows** in a rhythmic, wave-like pattern through an array of processing elements
- **Computations** occur simultaneously in multiple PEs, enabling massive parallelism
- **No global communication** required—each PE only communicates with immediate neighbours
- **High throughput** for matrix operations and signal processing workloads

This implementation provides a practical framework for understanding systolic designs, with full HDL source and synthesis infrastructure.

## 🏗️ Architecture

### System Hierarchy

```
boolean_systolic_top (Top Module)
├── Systolic Array (2×2)
│   ├── PE[0][0] (Top-Left)
│   ├── PE[0][1] (Top-Right)
│   ├── PE[1][0] (Bottom-Left)
│   └── PE[1][1] (Bottom-Right)
├── I/O Control Layer
│   ├── Switch Debouncer
│   ├── Button Edge Detector
│   ├── LED Driver
│   └── 7-Segment Display Controller (Dual)
└── Clock & Reset Management
```

### Processing Element (PE)

Each PE performs:
- **Multiply-Accumulate (MAC)** operations
- **Data routing** to adjacent PEs
- **Control signal propagation** for synchronization
- **Accumulator management** with clear operations

**PE I/O**:
```
Input:  clk, reset, clr_acc_in, in_a[15:0], in_b[15:0]
Output: clr_acc_out_a, clr_acc_out_b, out_a[15:0], out_b[15:0], acc[31:0]
```

## 📁 Project Structure

```
systolicbleh/
├── systolicbleh.srcs/
│   ├── sources_1/new/
│   │   ├── top_wrapper.v          # Top-level module with I/O control
│   │   ├── systolic_2x2_true.v    # 2×2 systolic array instantiation
│   │   ├── pe_systolic.v          # Individual processing element
│   │   └── boolean_board.xdc      # Board constraints & pin mappings
│   └── utils_1/                   # Utility modules and helpers
├── systolicbleh.runs/
│   ├── synth_1/                   # Synthesis results
│   └── impl_1/                    # Implementation & P&R results
├── systolicbleh.sim/              # Simulation testbenches
├── systolicbleh.hw/               # Hardware configuration
├── add_files.tcl                  # Vivado TCL build script
└── systolicbleh.xpr               # Vivado project file
```

## 🛠️ Prerequisites

### Hardware
- **FPGA Board**: Xilinx-based development board (tested with Artix-7)
- **Connections**: USB for JTAG programming
- **Power**: Standard development board power supply

### Software
- **Vivado Design Suite**: 2022.1 or later
  - Download: [Xilinx Vivado](https://www.xilinx.com/products/design-tools/vivado.html)
  - License: Free WebPACK license available
- **Git**: For version control (optional)

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/AngelinaMaryGeorge/FPGA-internship-project.git
cd systolic-bleh
```

### 2. Open in Vivado

**Method A: GUI**
1. Launch Vivado 2022.1+
2. File → Open Project
3. Select `systolicbleh.xpr`
4. Vivado auto-loads all source files and constraints

**Method B: TCL Script**
```bash
vivado -source add_files.tcl
```

### 3. Verify Design
```tcl
# In Vivado TCL Console:
open_project systolicbleh.xpr
open_run synth_1
report_timing
```

### 4. Program the Board

**Option A: Vivado GUI**
1. Tools → Program and Debug → Program Device
2. Select the generated `.bit` file from `systolicbleh.runs/impl_1/`
3. Click Program

**Option B: Hardware Manager**
```tcl
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices [lindex [get_hw_devices] 0] -file boolean_systolic_top.bit
close_hw_target
```

## 💻 Usage

### Input Control

| Input | Function |
|-------|----------|
| **Switches [15:0]** | Configure input operands and control signals |
| **Button[0]** | Global reset (clears all accumulators and state) |
| **Button[1-3]** | Optional control inputs (TBD) |

### Output Display

| Output | Function |
|--------|----------|
| **LEDs [15:0]** | Real-time computation status indicators |
| **7-Seg Display 0** | Right display—lower accumulator result bits |
| **7-Seg Display 1** | Left display—upper accumulator result bits |

### Example: Running a Computation

1. Set switches to input data values
2. Press button[0] to reset the system
3. Monitor LEDs for operation completion
4. View results on dual 7-segment displays

## 🔧 Building from Source

### Full Build Flow
```tcl
# Reset project
reset_project

# Run synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Run place & route
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
```

### Timing Analysis
```tcl
open_run impl_1
report_timing -sort_by group -max_paths 10
report_timing_summary
```

### Resource Utilisation
```tcl
report_utilization -hierarchical
```

## 🧪 Simulation & Testing

### Running Behavioural Simulation
```tcl
launch_simulation
run_all
```

See `systolicbleh.sim/sim_1/behav/` for testbench files and waveforms.

## 📊 Performance Metrics

| Metric | Value |
|--------|-------|
| **Clock Frequency** | 100 MHz |
| **Systolic Array Size** | 2×2 PEs |
| **Data Width** | 16-bit inputs, 32-bit outputs |
| **Throughput** | Up to 4 parallel MACs/cycle |
| **Latency** | ~4-6 cycles (depends on data routing) |

## 🔍 Design Highlights

### Debouncing Strategy
- Implements **Trixie debouncing** algorithm for mechanical switches
- Configurable debounce window (default: ~10 ms)
- Generates clean edge-triggered pulses from noisy switch inputs

### Clock Domain Crossing
- Synchronous design operating on a 100 MHz system clock
- All data flows respect clock domain constraints
- Reset signal properly propagated across all modules

### Resource Optimisation
- Minimal logic for control structures
- Data-dominated design (PEs consume ~70% of resources)
- Scalable: 2×2 array easily extends to 4×4, 8×8 configurations

## 📝 File Descriptions

| File | Purpose |
|------|---------|
| `top_wrapper.v` | Top-level module integrating systolic array with I/O controllers |
| `systolic_2x2_true.v` | 2×2 systolic array with PE instantiations and interconnect |
| `pe_systolic.v` | Single processing element (multiply-accumulate + routing) |
| `boolean_board.xdc` | Pin constraints and timing specifications for target board |

## 🤝 Contributing

Contributions are welcome! Areas for enhancement:

- [ ] Extend to 4×4 or larger arrays
- [ ] Add floating-point PE variants
- [ ] Implement AXI-based memory interface
- [ ] Create additional testbenches
- [ ] Documentation and tutorials
- [ ] Hardware-software co-design examples

**To contribute:**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📚 References

- [Xilinx Vivado Documentation](https://www.xilinx.com/support/documentation-navigation/design-hubs/vivado.html)
- [Systolic Array Research](https://en.wikipedia.org/wiki/Systolic_array)
- [HDL Best Practices](https://docs.xilinx.com/r/2022.1-English/ug901-vivado-synthesis/Introduction)

## 📄 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

## 👤 Authors

**Angelina Mary George, Neha Ann Philip, Bhagath S**  
FPGA Engineers | Hardware Design Enthusiast

- GitHub: [@elysian_, @angelinamarygeorge, @bhagathst](https://github.com/username)

## ⭐ Acknowledgments

- Xilinx for Vivado design tools and FPGA resources
- FPGA community for systolic array research and references
- Contributors and testers

---



Last Updated: June 2026
