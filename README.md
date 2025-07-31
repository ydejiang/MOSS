## Overview
## Multiple Observation Segment Search (MOSS) for Pulsars

**MOSS** is a flexible and parallelized pulsar search pipeline based on [PRESTO](https://www.cv.nrao.edu/~sransom/presto/) toolkit. It supports segmented and full-length searches across one or multiple observations of a single source. The script is optimized for large-scale processing of FAST data, especially for sources like globular clusters, but is adaptable for general pulsar search applications.

## Key Features

* Fully based on PRESTO utilities.
* Entire processing pipeline is parallelized.
* Integration time control is achieved via the number of FITS files per segment.
* Supports both single-beam and 19-beam FAST observations.
* Handles a wide range of search modes:

  * Single or multiple epochs
  * Segmented search
  * Full integration search
  * Overlapping-segmented search
  * Blind and targeted search

* Compatible with both general pulsar searches and specific globular cluster targets.

## Pipeline Flow:

1. RFI Mitigation (`rfifind`)
2. Dedispersion (`prepsubband` + `DDplan.py`, optional)
3. FFT (`realfft`)
4. Rednoise removal (`rednoise`, optional)
5. Acceleration Search (`accelsearch`)
6. Candidate Sifting (`ACCEL_sift.py`)
7. Folding (`prepfold`, optional)

Each step runs in parallel for optimal performance.

## Dependencies
* [PRESTO](https://www.cv.nrao.edu/~sransom/presto/)
* Bash 4+
* GNU Coreutils (`ls`, `xargs`, `find`, etc.)

## Directory Structure

```
project/
├── ACCEL_sift.py                 # Custom candidate sifting script
├── MOSS.sh         # Main pipeline script
├── /home/data/M13/               # Input directory of FITS files
│   ├── 20220823/
│   ├── 20221223/
│   └── ...
└── /home/data/ydj/search/   # Output directory
    ├── 20220823/
    │   ├── segment_*/
    │   └── segment_command/
    └── ...
```

## Usage

## 1. Configure Script Parameters

At the top of `MOSS.sh`, specify the required paths and parameters:

```bash
obs_dates=(20220823 20221223 ...)
file_Path=/home/data/M13
output_Dir=/home/data/ydj/search
Source_name=M13
PCSSP_sift=/home/data/code/ACCEL_sift.py
P=50  # Parallel processes, i.e., the number of cpu cores in parallel.
```

You can also adjust `files_per_segment`, `overlap_files`, and PRESTO settings such as `dmstep`, `zmax`, add another search parameters (e.g., `wmax`), etc.

## 2. Run the Script

```bash
bash MOSS.sh
```

This will:

* Process each observation date directory
* Generate command files for each processing step
* Execute all steps in parallel

## Output

* Segmented processing directories with logs
* Final candidate output from `ACCEL_sift.py`
* Intermediate files: `.dat`, `.fft`, `.red.fft`, `.accelcands`, etc.
* Aggregated command files in `ss_commands/`

### The following versions of the script are available:

1. MOSS_v1.sh: Parallel processing of one observation date at a time.

2. MOSS_v2.sh: Processing multiple observation dates simultaneously and in parallel.

3. MOSS_v11.sh and MOSS_v22.sh: Enhanced versions of v1 and v2, respectively, with red noise removal included.

4. MOSS_v2.sh.sub: A specialized version for Globular Clusters with known pulsars. It uses a narrow DM range and generates *.sub??? files outputs for folding.

5. Versions with the DDplan prefix use PRESTO’s DDplan.py to generate dedispersion plans, suitable for blind searches over wide DM ranges.

## Citation

This script is a framework and we welcome modifications tailored to your specific processing needs.

If you find this script helpful in your work, please cite our repository and the following paper:

Yin et al., 2025, APJ


