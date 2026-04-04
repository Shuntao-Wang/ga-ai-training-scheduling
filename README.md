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

<div align="center">
  <img src="images/x_vector.svg" alt="Task vector">
</div>

where $x_t$ is the **starting NPU index** for task $t$ (tasks are allocated contiguously).

### Objective Function

objective_function.svg

<div align="center">
  <img src="images/objective_function.svg" alt="Objective Function">
</div>

1. **Communication Time** (theoretical cumulative volume):
- *HD mode*:
 
<div align="center">
  <img src="images/HD_mode.svg" alt="HD mode">
</div>

- *Ring mode*:

<div align="center">
  <img src="images/Ring_mode.svg" alt="Ring mode">
</div>

2. **Penalty**: Number of overlapping NPUs + allocations exceeding total cluster size

### Constraints
- Contiguous and non-overlapping NPU allocation per task
- ![Constraints](images/x_constraints.svg)

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
│   ├── ga_runner.m            # Genetic Algorithm implementation
│   ├── fitness.m
│   └── utils/                 # Load tasks, comm time, local search
├── results/                   # Auto-generated plots & logs
└── config/                    # Scale-specific parameters
```
## Author
Shuntao Wang
