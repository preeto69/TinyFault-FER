# TinyFault-FER

### Inference-Aware RTL Fault Injection of an INT8 CNN Accelerator Datapath

![Python](https://img.shields.io/badge/Python-3.x-blue)
![TensorFlow](https://img.shields.io/badge/TensorFlow-TFLite-orange)
![Verilog](https://img.shields.io/badge/RTL-Verilog-green)
![Icarus](https://img.shields.io/badge/Simulation-Icarus_Verilog-lightgrey)
![Quartus](https://img.shields.io/badge/FPGA-Quartus_II-blue)

**TinyFault-FER** evaluates how transient single-bit faults in a signed 32-bit neural-network accumulator propagate to inference-level failures in a fully quantized INT8 CNN.

**Pipeline:**  
FER2013 → Compact CNN → Full-INT8 TFLite → RTL MAC/Accumulator → Bit-Flip Fault Injection → Inference Vulnerability Analysis → FPGA Synthesis

<p align="center">
  <img src="results/pipeline.png" width="1000">
</p>

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
| Overall decision-flip rate | **12.43%** |
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

A compact convolutional neural network was trained for **7-class facial-expression recognition** and converted to a full-integer TensorFlow Lite model.

- FP32 test accuracy: **62.45%**
- INT8 test accuracy: **62.54%**
- INT8–FP32 accuracy difference: **+0.09 percentage points**

The model was intentionally kept compact because the primary objective is **hardware fault analysis**, rather than maximizing facial-expression-recognition accuracy.

### 2. RTL Datapath

The final fully connected classifier of the deployed INT8 model was selected as the RTL fault-analysis target.

The analyzed arithmetic path is:

```text
signed INT8 activation × signed INT8 weight
                    ↓
          signed 16-bit product
                    ↓
          signed 32-bit accumulator
```

The final classifier contains **32 input features and 7 output neurons**.

Quantized activations, weights, biases, scales, and zero-points were extracted directly from the deployed TFLite model. Activation zero-point correction was incorporated into the RTL bias term to preserve the intended signed INT8 arithmetic path.

### 3. RTL Verification

The MAC/accumulator was implemented in SystemVerilog and simulated using **Icarus Verilog**.

Before fault injection, clean RTL accumulator outputs were compared against the Python integer reference reconstructed from the deployed TFLite tensors.

**Result: bit-exact Python ↔ RTL accumulator agreement.**

All **100 fault-campaign seeds** also produced clean reconstructed classifier decisions identical to the corresponding TFLite decisions.

**Clean reconstruction ↔ TFLite agreement: 100%.**

### 4. Fault-Injection Protocol

A transient single-bit fault was injected independently into each position of the signed 32-bit accumulator.

```text
100 inference samples
× 7 output neurons
× 32 accumulator bits
= 22,400 RTL fault injections
```

Each fault modifies one completed output-neuron accumulator before the final classification decision is evaluated.

A fault is defined as **inference-critical** when:

```text
faulty predicted class ≠ clean predicted class
```

This distinguishes numerical corruption from faults that actually alter the application-level inference decision.

---

## Fault-Injection Results

Across **22,400 RTL fault injections**:

- **12.43%** changed the final predicted class.
- **87.57%** preserved the clean decision.
- Vulnerability varied strongly with accumulator bit position.
- **Bit 31** was the most vulnerable accumulator position.
- Bit-31 corruption produced an **81.71% decision-flip rate**.

### Accumulator-Bit Vulnerability

<p align="center">
  <img src="results/accumulator_bit_vulnerability.png" width="850">
</p>

The bit-level results demonstrate substantial **fault-significance asymmetry**. Corruption of numerically significant accumulator positions is much more likely to propagate to a classification failure than corruption of lower-impact positions.

### Fault Outcome Distribution

<p align="center">
  <img src="results/fault_outcome_distribution.png" width="650">
</p>

Most injected arithmetic faults were masked at the inference level: **87.57%** preserved the original predicted class despite corruption of an accumulator value.

### Output-Neuron Vulnerability

<p align="center">
  <img src="results/output_neuron_vulnerability.png" width="850">
</p>

The campaign also evaluates how vulnerability varies across the seven final-layer output neurons.

Together, these results show that **numerical corruption and inference failure are not equivalent**. Hardware vulnerability should therefore be evaluated not only by whether an arithmetic value changes, but also by whether that corruption propagates to the final model decision.

---

## FPGA Synthesis

The registered MAC datapath was synthesized using **Quartus II 13.0 SP1** for an **Altera Cyclone IV E EP4CE22F17C6** device.

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

Quartus inferred the signed multiplication as an embedded multiplier resource.

The reported **169.55 MHz Fmax** corresponds to static timing analysis of the registered MAC datapath. External board-level I/O timing was not constrained or evaluated.

---

## Experimental Scope

TinyFault-FER focuses on a representative quantized neural-network arithmetic datapath rather than a complete CNN RTL implementation.

| Component | Scope |
|---|---|
| CNN execution | TensorFlow / TensorFlow Lite |
| Quantization | Full INT8 |
| RTL target | Final-layer MAC / 32-bit accumulator |
| RTL simulator | Icarus Verilog |
| Fault model | Transient single-bit accumulator flip |
| Fault positions | Bits 0–31 |
| Fault injections | 22,400 |
| FPGA analysis | Quartus II synthesis + static timing |
| Physical FPGA deployment | Not performed |

RTL simulation provides deterministic and repeatable control over fault location while allowing all 32 accumulator positions to be evaluated across thousands of inference scenarios.

---

## Reproducibility

### Repository Structure

```text
TinyFault-FER/
├── README.md
├── LICENSE
├── .gitignore
│
├── notebooks/
│   └── TinyFault_FER_Colab.ipynb
│
├── rtl/
│   ├── int8_mac_accum.sv
│   └── tb_fault_campaign.sv
│
├── quartus/
│   ├── int8_mac_accum.v
│   ├── quartus_top.v
│   ├── tinyfault_mac.qpf
│   ├── tinyfault_mac.qsf
│   ├── tinyfault_mac.sdc
│   └── compile.bat
│
├── results/
│   ├── pipeline.png
│   ├── accumulator_bit_vulnerability.png
│   ├── fault_outcome_distribution.png
│   └── output_neuron_vulnerability.png
│
└── reports/
    ├── rtl_summary.json
    ├── rtl_faults.csv
    └── quartus_resource_summary.txt
```

### Notebook Workflow

The Colab notebook performs the complete experimental pipeline:

1. train the compact CNN,
2. convert the model to full INT8 TFLite,
3. evaluate FP32 and INT8 accuracy,
4. extract deployed final-layer quantized tensors,
5. reconstruct clean integer accumulators,
6. generate RTL test vectors,
7. execute the Icarus Verilog fault campaign,
8. verify Python ↔ RTL arithmetic,
9. propagate faulty accumulators to inference decisions,
10. generate vulnerability summaries and plots.

### RTL Simulation

From the `rtl/` directory:

```bash
iverilog -g2012 -Wall \
    -o fault_campaign.vvp \
    int8_mac_accum.sv \
    tb_fault_campaign.sv

vvp fault_campaign.vvp
```

The raw injection-level RTL output is provided in:

```text
reports/rtl_faults.csv
```

The frozen campaign summary is provided in:

```text
reports/rtl_summary.json
```

### Quartus Synthesis

The synthesis project is available under `quartus/`.

```bash
quartus_sh --flow compile tinyfault_mac
```

Target device:

```text
Cyclone IV E EP4CE22F17C6
```

The compact synthesis/timing summary is provided in:

```text
reports/quartus_resource_summary.txt
```

---

## Key Takeaway

**Hardware faults are not equally important at the inference level.**

Across **22,400 RTL fault injections**, most accumulator corruptions did not change the CNN decision, while faults in high-impact accumulator positions—particularly **bit 31**—frequently propagated to classification failures.

The results motivate **inference-aware vulnerability analysis** as a complement to conventional low-level fault analysis when evaluating reliable quantized AI accelerators.
