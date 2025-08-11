#!/bin/bash
#******************************
#-------------------------------
#- dj.yin at foxmail dot com   -
#- Dejiang Yin, 2025-08-11     -   
#-------------------------------
# From ACCEL_sift.py to prepfold
##
# cp $PRESTO/examplescripts/ACCEL_sift.py .
# cd .. 
# python ACCEL_sift.py  > cands.txt
python /path/to/accel/ACCEL_sift.py  > cands.txt

##
grep -E "_ACCEL_*:*" cands.txt | awk '{split($1, arr, ":"); print arr[1], arr[2], $2, $4, $8}' > Cands.txt
file_values=""
cand_values=""
dm_values=""
p_values=""

while IFS= read -r line; do
	file=$(echo "$line" | awk '{print $1}')
	cand=$(echo "$line" | awk '{print $2}')
        dm=$(echo "$line" | awk '{print $3}')
	p=$(echo "$line" | awk '{print $5}')
	file_values+="$file "
	cand_values+="$cand "
        dm_values+="$dm "
	p_values+="$p "

done < "Cands.txt"

## 
file_values=($file_values)
cand_values=($cand_values)
dm_values=($dm_values)
p_values=($p_values)

rm prepfold_sub_commands.sh

for i in $(seq ${#file_values[*]}); do
	#dat_name=$(echo "$file_values[i-1]" | awk -F"_ACCEL_" '{print $1}')
    #echo "prepfold -noxwin -nosearch -topo -n 64 -npart 128 -accelcand ""${cand_values[i-1]}"" -accelfile ""${file_values[i-1]}.cand"" ""${dat_name}.dat"" " >> prepfold_dat_commands.sh
	echo "prepfold -noxwin -nosearch -topo -n 64 -npart 128 -dm ""${dm_values[i-1]}"" -accelcand ""${cand_values[i-1]}"" -accelfile ""${file_values[i-1]}.cand"" -o ""Pms_${p_values[i-1]}_${file_values[i-1]}"" ./subbands/*.sub??? " >> prepfold_sub_commands.sh
done

## 
cat prepfold_sub_commands.sh | xargs -n1 -I{} -P20 sh -c {}
