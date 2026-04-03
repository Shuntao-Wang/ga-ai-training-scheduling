
# GA-AI-Training-Scheduling

**Genetic Algorithm for Large-Scale AI Model Training Task Scheduling**

A MATLAB-based Genetic Algorithm (GA) solution for optimizing task scheduling in large-scale GPU/NPU clusters with Clos network topologies. The objective is to **minimize the total training completion time (makespan)** while reducing communication conflicts under resource constraints.


## Overview

This project addresses the challenge of scheduling multiple AI training tasks on large GPU/NPU clusters (256 to 12,288 cards) using a Clos (Fat-Tree) network. Each task has different data parallelism (DP), collective communication patterns (HD or Ring), and communication volumes.

-  Mixed-Integer Programming (MIP) is often used for exact modeling, but it only suits for small scale datasets
- Switched to **Genetic Algorithm (GA)** due to high computational complexity at scale
- Tested on three dataset sizes: **256, 512, and 12,288 NPUs**

**Keywords**: Genetic Algorithm, Task Scheduling, AI Training, Clos Network, Communication Conflict, Makespan Minimization



## Mathematical Model

### Decision Variables (Chromosome Encoding)
Each solution is an integer vector:
`x = [x_1, x_2, ..., x_T], x_t ∈ Z^+`
where $x_t$ is the **starting NPU index** for task $t$ (tasks are allocated contiguously).

### Objective Function
$$
\min f(\mathbf{x}) = \sum_{t=1}^T \text{CommTime}(t, x_t) + 10000 \times \text{Penalty}(\mathbf{x})
$$

- **Communication Time** (theoretical cumulative volume):
  - HD mode:
    $$
    \text{CommTime}_{\text{HD}} = \sum_{j=0}^{\log_2 DP_t - 1} \frac{1}{2^{j+1}}
    $$
  - Ring mode:
    $$
    \text{CommTime}_{\text{Ring}} = (DP_t - 1) \times \frac{1}{DP_t}
    $$

- **Penalty**: Number of overlapping NPUs + allocations exceeding total cluster size

### Constraints
- Contiguous and non-overlapping NPU allocation per task
- $1 \leq x_t \leq N_{\mathrm{total}} - \mathrm{total\_npu}_t + 1$

(The original MIP formulation also explicitly modeled per-stage communication paths and bandwidth timing — see `src/mip/` for details.)



## Dataset

- **Scales**: 256 / 512 / 12,288 NPUs
- **Location**: `data/dataset/{scale}/`
- **Format**: Multiple `X.json` files per scale
- **Key fields per task**:
  - `task_id`, `total_npu`, `DP`, `cc` ("HD" or "Ring")
  - `com_pair`, `com_data` (communication pairs and volumes per stage)



## Genetic Algorithm Highlights

- **Encoding**: Integer vector (starting NPU positions)
- **Population Size**: 300–500
- **Crossover**: 0.8 (adaptive feasible)
- **Mutation**: 0.3 (`mutationadaptfeasible`)
- **Elitism**: Top 15%–20%
- **Selection**: Tournament
- **Local Search**: Every 10 generations (improves solution quality)
- **Independent Runs**: 10–15 runs, best solution retained



## Quick Start

### Requirements
- MATLAB R2020a or later (with Global Optimization Toolbox)
- JSON datasets placed in `data/dataset/`

### Run the Code
```matlab
cd src
% Choose scale: 256, 512, or 12288
scale = 12288;   
run main.m
```
The script will automatically:

-   Load tasks
-   Run GA
-   Save best solution
-   Generate convergence plot, Gantt chart, and allocation heatmap

## Experimental Results (Summary)

| Scale | Tasks | Best Completion Time | Notes |
|-----|-----|-----|-----|
| 256 NPU | 3| 2.7500 | Small scale |
| 512 NPU | 3 | 2.7812 | Medium scale |
| 12,288 NPU | 6 | 5.9629 | Large scale (production-like) |

Full results, convergence curves, and Gantt charts are in the `results/` folder.

## Repository Structure

```
ga-ai-training-scheduling/
├── README.md
├── LICENSE
├── data/
│   └── dataset/               # 256, 512, 12288 folders
├── src/
│   ├── main.m                 # Main entry point
│   ├── ga_runner.m
│   ├── fitness.m
│   └── utils/                 # Load tasks, comm time, local search
├── results/                   # Auto-generated plots & logs
└── config/                    # Scale-specific parameters
```
## Author
Shuntao Wang
