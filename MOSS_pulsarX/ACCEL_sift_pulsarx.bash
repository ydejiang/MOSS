#!/bin/bash
#-------------------------------
#- dj.yin at foxmail dot com   -
#- Dejiang Yin, 2024-12-30     -   
#-------------------------------
# Source Information
telescope=FAST 
srcname=NGC6517    # default_value("PSRJ0000+00"), "Souce name")
ra=18:01:50.52     # default_value("00:00:00"), "RA (hhmmss.s)")
dec=-08:57:31.60   # default_value("00:00:00"), "DEC (ddmmss.s)")
rootname=NGC6517   # ("rootname,o", value<string>()->default_value("J0000-00"), "Output rootname") 
##
zmax=_ACCEL_20
# zmax=_ACCEL_10_JERK_20  # Uncomment for jerk searches

# Path to Python scripts
ACCEL_sift_pulsarx=/home/data/NGC6517/20190625/demo/pulsarX_sifting/ACCEL_sift_pulsarx.py
fast_fold.template=/home/software/PulsarX/include/template/fast_fold.template
# Only accel:
python ""${ACCEL_sift_pulsarx}"" -ACCEL 20 -minP 2. -maxP 6.8 -minS 1 -maxS 40 2> pulsarX_cands.List
# For jerk search:
#python ""${python_1}"" -ACCEL 300 -JERK 900 -minP 2. -maxP 10.8 -rDM 4 -minS 6 -maxS 40 2> pulsarX_cands.List

# For folding
FileList=$(cat *.FileList)
psrfold_fil2 -v -t 4 --noarch --template ${fast_fold.template} --candfile pulsarX_cands.List --plotx -n 64 -b 64 --clfd 2  -z kadaneF 8 4 zdot --telescope ${telescope} --srcname ${srcname} --ra ${ra} --dec ${dec} -o ${rootname} --cont --psrfits "${FileList}"

# Move result files to final folders (robust to large number of files)
mkdir -p pulsarX
find . -maxdepth 1 -name "*.png" -exec mv -t ./pulsarX {} +
mv -rf *.cands ./pulsarX

echo "[INFO] All steps completed."
date
