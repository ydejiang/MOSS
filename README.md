 # Multiple Observation Segment Search (MOSS) for Pulsars

MOSS is a flexible and parallelized pulsar search pipeline based on [PRESTO](https://www.cv.nrao.edu/~sransom/presto/) toolkit. It supports segmented and full-length searches across one or multiple observations of a single source. The script is optimized for large-scale processing of FAST data, especially for sources like globular clusters, but is adaptable for general pulsar search applications.

---

Key Features

Fully based on PRESTO utilities.

Entire processing pipeline is parallelized.

Integration time control is achieved via the number of FITS files per segment.

Supports both single-beam and 19-beam FAST observations.

Handles a wide range of search modes:

Single or multiple epochs

Segmented search

Full integration search

Cross-segmented search

Blind and targeted search

Includes support for overlapping segments.

Compatible with both general pulsar searches and specific globular cluster targets.

Pipeline Flow:

RFI Mitigation (rfifind)

Dedispersion (prepsubband + DDplan.py)

FFT (realfft)

Rednoise removal (rednoise, optional)

Acceleration Search (accelsearch)

Candidate Sifting (ACCEL_sift.py)

Folding (prepfold)

Each step runs in parallel for optimal performance.

---

## Directory Structure

```
project/
├── PCSSP_sift.sh                  # Custom candidate sifting script
├── run_segment_search.sh         # Main pipeline script
├── /home/data/M13/               # Input directory of FITS files
│   ├── 20220823/
│   ├── 20221223/
│   └── ...
└── /home/data/ydj/M13/20231108/segment_obs/   # Output directory
    ├── 20220823/
    │   ├── segment_*/
    │   └── segment_command/
    └── ...
```

---

## Usage

### 1. Configure Script Parameters

At the top of `run_segment_search.sh`, specify the required paths and parameters:

```bash
obs_dates=(20220823 20221223 ...)
file_Path=/home/data/M13
output_Dir=/home/data/ydj/M13/20231108/segment_obs
Source_name=M13
PCSSP_sift=/path/to/PCSSP_sift.sh
P=50  # Parallel processes
```

You can also adjust `files_per_segment`, `overlap_files`, and PRESTO settings such as `dmstep`, `zmax`, etc.

### 2. Run the Script

```bash
bash run_segment_search.sh
```

This will:

* Process each observation date directory
* Split FITS files into overlapping segments
* Generate command files for each step
* Execute all steps in parallel

---

## Output

* Segment-wise processing directories with logs
* Final candidate output from `PCSSP_sift.sh`
* Intermediate files: `.dat`, `.fft`, `.red.fft`, `.accelcands`, etc.
* Aggregated command files in `ss_commands/`

---

## Dependencies

* [PRESTO](https://www.cv.nrao.edu/~sransom/presto/)
* Bash 4+
* GNU Coreutils (`ls`, `xargs`, `find`, etc.)

---

## License

This project is open for research and non-commercial use.

---

## Contact

**Dejiang Yin**
PhD Candidate, Guizhou University
📧 [dj.yin@foxmail.com](mailto:dj.yin@foxmail.com)



# MOSS.bash: Multi-Observation Segment Search Pipeline

**Author:** Dejiang Yin ([dj.yin@foxmail.com](mailto:dj.yin@foxmail.com))
**Version:** v1.0
**Last Updated:** July 2025

## Overview

**MOSS.bash** is a flexible and parallelized pulsar search pipeline based on PRESTO. It supports segmented and full-length searches across one or multiple observations of a single source. The script is optimized for large-scale processing of FAST data, especially for sources like globular clusters, but is adaptable for general pulsar search applications.

### Key Features

* Fully based on PRESTO utilities.
* Entire processing pipeline is parallelized.
* Integration time control is achieved via the number of FITS files per segment.
* Supports both single-beam and 19-beam FAST observations.
* Handles a wide range of search modes:

  * Single or multiple epochs
  * Segmented search
  * Full integration search
  * Cross-segmented search
  * Blind and targeted search
* Includes support for overlapping segments.
* Compatible with both general pulsar searches and specific globular cluster targets.

### Pipeline Flow:

1. RFI Mitigation (`rfifind`)
2. Dedispersion (`prepsubband` + `DDplan.py`)
3. FFT (`realfft`)
4. Rednoise removal (`rednoise`, optional)
5. Acceleration Search (`accelsearch`)
6. Candidate Sifting (`ACCEL_sift.py`)
7. Folding (`prepfold`)

Each step runs in parallel for optimal performance.

## Requirements

* Bash shell
* PRESTO suite installed and available in `PATH`
* Python 3 (for `ACCEL_sift.py`)
* NumPy, Matplotlib (optional for sifting/plotting)

## Directory Structure

```
project/
├── MOSS.bash                # Main script
├── ACCEL_sift.py            # Candidate sifting script
├── obs_dates.txt            # Observation dates list
├── DDplans/                 # Output of DDplan.py
├── RFIs/                    # RFI masks
├── PREPSUB/                 # Dedispersed data
├── FFT/                     # FFT results
├── REDNOISE/                # Rednoise results
├── ACCEL/                   # Acceleration search results
├── FOLDS/                   # Folded candidates
└── LOGS/                    # Logs for each run
```

## Usage

Edit the `MOSS.bash` script to set:

* `obs_dates` – array of observation date tags
* `file_Path` – path to FITS files (organized by date subfolders)
* Search parameters: zmax, DM range, number of files per segment, overlap, etc.

Then run:

```bash
bash MOSS.bash
```

To parallelize:

```bash
parallel -j 4 < command_list.txt
```

## Output

* Candidate plots from `prepfold`
* Sifted results and summary tables from `ACCEL_sift.py`
* Log files for each step and observation

## Notes

* The pipeline automatically detects and processes FITS files from multiple dates.
* FITS files per segment can be tuned to match desired integration time.
* RFI mask is generated per segment or reused as needed.
* The pipeline is modular and can be adapted for other telescopes or search types.

## Contact

For questions or collaborations:
**Dejiang Yin**
[dj.yin@foxmail.com](mailto:dj.yin@foxmail.com)

