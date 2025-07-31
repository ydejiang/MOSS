 Here MOSS files.
# Multiple Observation Segment Search (MOSS) for Pulsars

This project contains a Bash pipeline to conduct a segmented and parallelized pulsar search using the [PRESTO](https://www.cv.nrao.edu/~sransom/presto/) toolkit. The script processes multiple epochs of observation data and performs a sequence of standard pulsar search steps in parallel. It is particularly suitable for large datasets observed with the FAST telescope or similar facilities.

---

## Features

* Supports multiple observation epochs
* Segment-wise search with overlapping FITS file blocks
* Fully parallelized execution using `xargs`
* Automatically generates and executes commands for:

  * `rfifind` (RFI mask generation)
  * `prepsubband` (sub-band dedispersion)
  * `realfft` / `realfft -inv` (Fourier transforms)
  * `rednoise` (red noise filtering)
  * `accelsearch` (acceleration search)
  * Custom candidate sifting with `PCSSP_sift.sh`

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
