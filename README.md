[![DOI](https://zenodo.org/badge/965935150.svg)](https://doi.org/10.5281/zenodo.16784278)
## Multiple Observation Segment Search (MOSS) for Pulsars

**MOSS** is a flexible and parallelized pulsar search pipeline based on [PRESTO](https://www.cv.nrao.edu/~sransom/presto/) toolkit. It supports segmented and full-length searches across one or multiple observations of a single source or multiple objects. The script is designed for large-scale processing of the Five-hundred-meter Aperture Spherical radio Telescope (FAST) observation data (The observation data is saved to many consecutive **.fits** files), especially for targeted sources like globular clusters, but is adaptable for general pulsar search applications.

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

* RFI Mitigation (`rfifind`)
* Dedispersion (`prepsubband` + `DDplan.py`, optional)
* FFT (`realfft`)
* Rednoise removal (`rednoise`, optional)
* Acceleration Search (`accelsearch`)
* Candidate Sifting (`ACCEL_sift.py`)
* Folding (`prepfold`, optional)

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
* Intermediate files: `.dat`, `.fft`, `.red.fft`, etc.
* Aggregated command files in `ss_commands/`

### The following versions of the script are available:

* MOSS_v1.sh: Parallel processing of one observation at a time.

* MOSS_v2.sh: Processing multiple observations simultaneously and in parallel.

* MOSS_v11.sh and MOSS_v22.sh: Enhanced versions of v1 and v2, respectively, with red noise removal included.

* MOSS_v2.sh.sub: A specialized version for Globular Clusters with known pulsars. It uses a narrow DM range and generates *.sub??? files outputs for folding.

* Versions with the DDplan prefix use PRESTO’s DDplan.py to generate dedispersion plans, suitable for blind searches over wide DM ranges.

## Citation

This script is a framework and we welcome modifications tailored to your specific processing needs.

If the scripts in this repository are helpful to your work, please cite our repository links and the paper. Thank you!

https://github.com/ydejiang/MOSS

https://ui.adsabs.harvard.edu/abs/2025ApJ...991..177Y/abstract
```
@ARTICLE{2025ApJ...991..177Y,
       author = {{Yin}, Dejiang and {Wang}, Lin and {Zhang}, Li-yun and {Qian}, Lei and {Li}, Baoda and {Liu}, Kuo and {Peng}, Bo and {Dai}, Yinfeng and {Li}, Yaowei and {Pan}, Zhichen},
        title = "{Illuminating Hidden Pulsars: Scintillation-enhanced Discovery of Two Binary Millisecond Pulsars in M13 with FAST}",
      journal = {\apj},
     keywords = {Globular star clusters, Millisecond pulsars, Radio telescopes, 656, 1062, 1360, High Energy Astrophysical Phenomena, High Energy Physics - Phenomenology},
         year = 2025,
        month = oct,
       volume = {991},
       number = {2},
          eid = {177},
        pages = {177},
          doi = {10.3847/1538-4357/adfa14},
archivePrefix = {arXiv},
       eprint = {2508.05998},
 primaryClass = {astro-ph.HE},
       adsurl = {https://ui.adsabs.harvard.edu/abs/2025ApJ...991..177Y},
      adsnote = {Provided by the SAO/NASA Astrophysics Data System}
}
```
