# TinyFault-FER

### Inference-Aware RTL Fault Injection of an INT8 CNN Accelerator Datapath

![Python](https://img.shields.io/badge/Python-3.x-blue)
![TensorFlow](https://img.shields.io/badge/TensorFlow-TFLite-orange)
![Verilog](https://img.shields.io/badge/RTL-Verilog-green)
![Icarus](https://img.shields.io/badge/Simulation-Icarus_Verilog-lightgrey)
![Quartus](https://img.shields.io/badge/FPGA-Quartus_II-blue)

**TinyFault-FER** investigates how transient single-bit faults in a signed 32-bit neural-network accumulator propagate to inference-level classification failures in a fully quantized INT8 CNN.

**Pipeline:**  
FER2013 → Compact CNN → INT8 TFLite → RTL MAC/Accumulator → Bit-Flip Fault Injection → Inference Vulnerability Analysis → FPGA Synthesis

---

## Headline Results

| Metric | Result |
|---|---:|
| FP32 test accuracy | **62.45%** |
| INT8 test accuracy | **62.54%** |
| INT8–FP32 accuracy difference | **+0.09 percentage points** |
| Validated inference seeds | **100** |
| RTL fault injections | **22,400** |
| RTL ↔ Python accumulator verification | **Bit-exact** |
| Clean reconstruction ↔ TFLite agreement | **100%** |
| Overall inference decision-flip rate | **12.43%** |
| Most vulnerable accumulator bit | **Bit 31** |
| Bit-31 decision-flip rate | **81.71%** |
| FPGA target | **Cyclone IV E EP4CE22F17C6** |
| Logic elements | **64** |
| Registers | **64** |
| Embedded multiplier resources | **1** |
| Worst-case registered-datapath Fmax | **169.55 MHz** |

---

## Methodology

### 1. Quantized CNN Workload

A compact convolutional neural network was trained for 7-class facial-expression recognition and converted to a full-integer TensorFlow Lite model.

- FP32 test accuracy: **62.45%**
- INT8 test accuracy: **62.54%**
- INT8–FP32 accuracy difference: **+0.09 percentage points**

The CNN was intentionally kept compact because the primary objective is hardware fault analysis rather than architecture optimization.

### 2. RTL Datapath

The deployed model's final fully connected classifier was selected as the RTL analysis target.

```text
signed INT8 activation × signed INT8 weight
                    ↓
          signed 16-bit product
                    ↓
          signed 32-bit accumulator
```

Actual quantized activations, weights, biases, scales, and zero-points were extracted from the deployed TFLite model.

Activation zero-point correction was folded into the RTL bias term to preserve the intended signed INT8 datapath.

### 3. RTL Verification

The MAC/accumulator was implemented in Verilog and evaluated using **Icarus Verilog**.

Clean RTL accumulator outputs were compared against the Python/TFLite-derived integer reference before fault injection.

**Result: bit-exact accumulator agreement.**

All **100 candidate inference seeds** produced clean reconstructed classifier decisions that exactly matched the deployed TFLite model, yielding **100% clean reconstruction agreement**.

### 4. Fault-Injection Protocol

A transient single-bit fault model was applied independently to every position of the signed 32-bit accumulator.

```text
100 inference samples
× 7 output neurons
× 32 accumulator bits
= 22,400 RTL fault injections
```

A fault was considered **inference-critical** when the corrupted accumulator changed the final predicted class relative to the clean inference.

---

## Fault-Injection Results

Across **22,400 RTL fault injections**:

- **12.43%** changed the final inference decision.
- **87.57%** preserved the clean decision.
- Vulnerability varied substantially with accumulator bit position.
- **Bit 31** was the most vulnerable location.
- Bit-31 corruption produced an **81.71% decision-flip rate**.

The results show that numerical corruption and inference failure are not equivalent. Many accumulator faults remain masked at the application level, while faults in numerically significant accumulator positions are substantially more likely to propagate into classification errors.

---

## FPGA Synthesis

The registered MAC datapath was synthesized using **Quartus II 13.0 SP1** for an **Altera Cyclone IV E EP4CE22F17C6** target.

| Resource / Timing Metric | Result |
|---|---:|
| Logic elements | **64** |
| Registers | **64** |
| Embedded multiplier resources | **1** |
| Memory bits | **0** |
| PLLs | **0** |
| Timing constraint | **100 MHz** |
| Worst-case setup slack @ 100 MHz | **+4.102 ns** |
| Worst-case registered-datapath Fmax | **169.55 MHz** |

Quartus inferred the signed multiplier as an embedded multiplier resource.

The reported Fmax corresponds to static timing analysis of the **registered MAC datapath**. External board-level I/O timing was not modeled.

---

## Experimental Scope

This project evaluates a representative quantized neural-network arithmetic datapath rather than claiming a complete CNN RTL implementation.

- **CNN inference:** TensorFlow / TensorFlow Lite
- **Fault target:** final-layer INT8 MAC / 32-bit accumulator
- **RTL simulation:** Icarus Verilog
- **Fault model:** transient single-bit accumulator corruption
- **FPGA analysis:** Quartus II synthesis and static timing
- **Physical FPGA deployment:** not performed

RTL simulation enables deterministic and repeatable fault injection across every accumulator bit and thousands of inference scenarios without requiring specialized physical fault-injection hardware.

---

## Reproducibility

The repository contains the full experimental workflow:

```text
notebooks/   CNN training, INT8 conversion, tensor extraction and analysis
rtl/         MAC/accumulator RTL and fault-injection testbench
quartus/     FPGA synthesis and timing project
results/     Figures and vulnerability plots
reports/     Fault-campaign and synthesis summaries
```

### RTL Simulation

```bash
iverilog -g2012 -o fault_campaign.vvp \
    int8_mac_accum.sv \
    tb_fault_campaign.sv

vvp fault_campaign.vvp
```

### Quartus Synthesis

```bash
quartus_sh --flow compile tinyfault_mac
```

---

## Key Takeaway

**Hardware faults are not equally important at the inference level.**

In this experiment, most injected accumulator faults preserved the CNN decision, whereas corruption of high-impact accumulator positions—particularly **bit 31**—frequently changed the predicted class.

This motivates **inference-aware vulnerability analysis** as a complement to conventional low-level fault analysis when evaluating reliable quantized AI accelerators.
