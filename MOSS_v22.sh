#!/bin/bash
# Multiple Observations Segment Search 
# @Dejiang Yin, dj.yin@foxmail.com, 20240616
#****************************************************
#-----------------------------------------------------

#-----------------------------------------------------
# The observation containing the different dates, as following
obs_dates=(20220823 20221223 20230423 20230823 20231223)
# The path of your fits data for one source, as following:
file_Path=/home/data/M13
# The path for you to save the searching results, as following:
output_Dir=/home/data/ydj/M13/20231108/segment_obs
# The name of your observation source name, as follow:
Source_name=M13
#-----------------------------------------------------
# The path for sifting code, as followiing:
PCSSP_sift=/home/data/ydj/M13/20231108/PCSSP_sift.sh
#-----------------------------------------------------
# Setting for ls *. | xargs -n1 -P{} -I{} ... # ""${P}"",-P, --max-procs=MAX-PROCS  Run up to max-procs processes at a time.
P=50
#-----------------------------------------------------
# The number of fits file for each segment searching of each observation.
files_per_segment=220
# The number of overlapping files between segments
overlap_files=110
#-----------------------------------------------------
# Setting for prepsubbad -nsub {} -lodm {} -dmstep {} -numdms {} -downsamp {}
nsub=1024
lodm=41.5
dmstep=0.05
numdms=80
downsamp=1
#-----------------------------------------------------
# Setting for accelsearch -zmax {} -numharm {} -sigma {}
zmax=520
numharm=32
sigma=2.0
#-----------------------------------------------------
# The command setting for the searching routines,
rfifind="rfifind -time 2.0 -ignorechan 680:810 "
prepsubband="prepsubband -nobary -nsub ${nsub} -lodm ${lodm} -dmstep ${dmstep} -numdms ${numdms} -downsamp ${downsamp} -ignorechan 680:810  "
realfft="realfft -fwd "
rednoise="rednoise "
realfft_inv="realfft -inv "
accelsearch="accelsearch -zmax ${zmax} -numharm ${numharm} -sigma ${sigma} "
#-----------------------------------------------------

#-----------------------------------------------------
# Define function to process fits files in segments for multiple observations segment search
multiple_obs_segment_search() {
    File_Path="${file_Path}/${1}"
    mkdir -p "${output_Dir}/${1}"
    Output_Dir="${output_Dir}/${1}"
    Obs_data=${1}
    # Get the list of fits files in the specified directory  
    fits_files=($(ls "${File_Path}"/*.fits))                                                                                                                                                         
    # Calculate the number of segments based on the number of fits files                                                                                            
    total_files=${#fits_files[@]}                                                                                                                                                                
    total_segments=$(((total_files - overlap_files) / (files_per_segment - overlap_files)))                                                                                               
    if [ $(((total_files - overlap_files) % (files_per_segment - overlap_files))) -ne 0 ]; then                                                                                                
        total_segments=$((total_segments + 1))                                                                                                                      
    fi                                                                                                                                             
    #-----------------------------------------------------
    # Define function to process fits files in segments for "rfifind"                                                                                               
    rfifind_segment() {                                                                                                                                             
        segment_number=$1          
        start_index=$((segment_number * (files_per_segment - overlap_files)))                                                                                                                                 
        end_index=$((start_index + files_per_segment - 1))                                                                                                          
        if [ $end_index -ge $total_files ]; then                                                                                                                    
            end_index=$((total_files - 1))                                                                                                            
        fi                                                                                                                                                          
        # Create a directory for the segment if it doesn't exist                                                                                                    
        segment_dir="${Output_Dir}/segment_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"                                                
        mkdir -p "$segment_dir"                                                                                                                                     
        # Generate rfifind command with modified output name and directory                                                                                          
        output_name="${Source_name}_${Obs_data}_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"                                                                      
        echo "cd ${segment_dir} && ${rfifind} -o ${output_name} \$(ls ${File_Path}/*.fits | tail -n +$((start_index + 1)) | head -n $((end_index - start_index + 1))) > ${segment_dir}/${output_name}_rfifind.log"
    }                                                                                                                                                               
    #----------------------------------------------------- 
    # Define function to process fits files in segments for "prepsubband"  
    prepsubband_segment() {          
        segment_number=$1
        start_index=$((segment_number * (files_per_segment - overlap_files)))
        end_index=$((start_index + files_per_segment - 1))
        if [ $end_index -ge $total_files ]; then
            end_index=$((total_files - 1))
        fi
        # Create a directory for the segment if it doesn't exist                                                                                                    
        segment_dir="${Output_Dir}/segment_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"
        # Generate rfifind command with modified output name and directory                                                                                          
        output_name="${Source_name}_${Obs_data}_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"
        echo "cd ${segment_dir} && ${prepsubband} -o ${output_name} -mask ${output_name}_rfifind.mask \$(ls ${File_Path}/*.fits | tail -n +$((start_index + 1)) | head -n $((end_index - start_index + 1))) > ${segment_dir}/${output_name}_prepsubband.log"                                                                                                                                                                        
    }
    #-----------------------------------------------------                                      
    # Define function to process fits files in segments for "realfft"                                                                                       
    realfft_segment() {                                                                                                                                     
        segment_number=$1
        start_index=$((segment_number * (files_per_segment - overlap_files)))
        end_index=$((start_index + files_per_segment - 1))
        if [ $end_index -ge $total_files ]; then
            end_index=$((total_files - 1))
        fi
        # Create a directory for the segment if it doesn't exist                                                                                                    
        segment_dir="${Output_Dir}/segment_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"
        # Generate rfifind command with modified output name and directory                                                                                          
        output_name="${Source_name}_${Obs_data}_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"  
        # echo "cd ${segment_dir} && ls ./*.dat | xargs -n1 -I{} echo \"cd ${segment_dir} && ${realfft} {}\" >> ${segment_dir}/${output_name}_realfft.txt" 
	echo "cd ${segment_dir} && find . -maxdepth 1 -name \"*.dat\" | sort -V | xargs -n1 -I{} echo \"cd ${segment_dir} && ${realfft} {}\" >> ${segment_dir}/${output_name}_realfft.txt"
    }                                                                                                                                                       
    #-----------------------------------------------------                                      
    # Define function to process fits files in segments for "rednoise"  
    rednoise_segment() {
        segment_number=$1
        start_index=$((segment_number * (files_per_segment - overlap_files)))
        end_index=$((start_index + files_per_segment - 1))
        if [ $end_index -ge $total_files ]; then
            end_index=$((total_files - 1))
        fi
        # Create a directory for the segment if it doesn't exist                                                                                                    
        segment_dir="${Output_Dir}/segment_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"
        # Generate rfifind command with modified output name and directory                                                                                          
        output_name="${Source_name}_${Obs_data}_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"  
        output_name="${Source_name}_${Obs_data}_s$((${segment_number}+1))_$((${start_index}+1))-$((${end_index}+1))fits"
        # echo "cd ${segment_dir} && ls ./*.fft | xargs -n1 -I{} echo \"cd ${segment_dir} &&  ${rednoise} {}\" >> ${segment_dir}/${output_name}_rednoise.txt"                  
	echo "cd ${segment_dir} && find . -maxdepth 1 -name \"*.fft\" | sort -V | xargs -n1 -I{} echo \"cd ${segment_dir} &&  ${rednoise} {}\" >> ${segment_dir}/${output_name}_rednoise.txt"
    }
    #-----------------------------------------------------
    # Define function to process fits files in segments for "realfft -inv"
    realfft_inv_segment() {
        segment_number=$1
        start_index=$((segment_number * (files_per_segment - overlap_files)))
        end_index=$((start_index + files_per_segment - 1))
        if [ $end_index -ge $total_files ]; then
            end_index=$((total_files - 1))
        fi
        # Create a directory for the segment if it doesn't exist                                                                                                    
        segment_dir="${Output_Dir}/segment_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"
        # Generate rfifind command with modified output name and directory                                                                                          
        output_name="${Source_name}_${Obs_data}_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"  
        # echo "cd ${segment_dir} && ls ./*_red.fft | xargs -n1 -I{} echo \"cd ${segment_dir} &&  ${realfft_inv} {}\" >> ${segment_dir}/${output_name}_realfft_inv.txt"      
	echo "cd ${segment_dir} && find . -maxdepth 1 -name \"*_red.fft\" | sort -V | xargs -n1 -I{} echo \"cd ${segment_dir} &&  ${realfft_inv} {}\" >> ${segment_dir}/${output_name}_realfft_inv.txt"  
    }
    #-----------------------------------------------------
    # Define function to process fits files in segments for "accelsearch"                                                                                                            
    accelsearch_segment() {                                                                                                                                                          
        segment_number=$1
        start_index=$((segment_number * (files_per_segment - overlap_files)))
        end_index=$((start_index + files_per_segment - 1))
        if [ $end_index -ge $total_files ]; then
            end_index=$((total_files - 1))
        fi
        # Create a directory for the segment if it doesn't exist                                                                                                    
        segment_dir="${Output_Dir}/segment_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"
        # Generate rfifind command with modified output name and directory                                                                                          
        output_name="${Source_name}_${Obs_data}_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"  
        # echo "cd ${segment_dir} && ls ./*_red.fft | xargs -n1 -I{} echo \"cd ${segment_dir} && ${accelsearch} {}\" >> ${segment_dir}/${output_name}_accelsearch.txt" 
	echo "cd ${segment_dir} && find . -maxdepth 1 -name \"*_red.fft\" | sort -V | xargs -n1 -I{} echo \"cd ${segment_dir} && ${accelsearch} {}\" >> ${segment_dir}/${output_name}_accelsearch.txt" 
    }                                                                                                                                                                                
    #-----------------------------------------------------
    # Define function to process fits files in segments for "sifting"                                                     
    sifting_segment() {                                                                                                   
        segment_number=$1
        start_index=$((segment_number * (files_per_segment - overlap_files)))
        end_index=$((start_index + files_per_segment - 1))
        if [ $end_index -ge $total_files ]; then
            end_index=$((total_files - 1))
        fi
        # Create a directory for the segment if it doesn't exist                                                                                                    
        segment_dir="${Output_Dir}/segment_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"
        # Generate rfifind command with modified output name and directory                                                                                          
        output_name="${Source_name}_${Obs_data}_s$((${segment_number} + 1))_$((${start_index} + 1))-$((${end_index} + 1))fits"  
        echo "cd ${segment_dir} && bash ${PCSSP_sift} "                                                                  
    }                                                                                                                     
    #*****************************************************                                            
    #-----------------------------------------------------
    # porferming above defined functions
    #-----------------------------------------------------

    # Process fits files in segments                               
    # rfifind
    for ((i = 0; i < total_segments; i++)); do                     
        rfifind_segment $i >> ${Output_Dir}/rfifind_segment.txt                  
    done                                                           
    # prepsubband
    for ((i = 0; i < total_segments; i++)); do                               
        prepsubband_segment $i >> ${Output_Dir}/prepsubband_segment.txt                 
    done                                                                     
    # realfft 
    for ((i = 0; i < total_segments; i++)); do           
        realfft_segment $i >> ${Output_Dir}/realfft_segment.txt
    done                                                 
    # rednoise    
    for ((i = 0; i < total_segments; i++)); do
        rednoise_segment $i >> ${Output_Dir}/rednoise_segment.txt
    done
    # realfft -inv
    for ((i = 0; i < total_segments; i++)); do
        realfft_inv_segment $i >> ${Output_Dir}/realfft_inv_segment.txt
    done
    # accelsearch
    for ((i = 0; i < total_segments; i++)); do                       
        accelsearch_segment $i >> ${Output_Dir}/accelsearch_segment.txt             
    done                                                             
    # sifting
    for ((i = 0; i < total_segments; i++)); do                    
        sifting_segment $i >> ${Output_Dir}/sifting_segment.txt                  
    done  
    #-----------------------------------------------------
    # Others
    # remove the command.txt to segment_command                
    mkdir -p ${Output_Dir}/segment_command                  
    mv ${Output_Dir}/*_segment.txt ${Output_Dir}/segment_command       
    #-----------------------------------------------------
}

#*****************************************************                                            
#-----------------------------------------------------
# The all observations to search for psulsar with segment search, as following
#-----------------------------------------------------
#***************************************************** 

for obs_date in "${obs_dates[@]}"; do
    multiple_obs_segment_search $obs_date
done

#*****************************************************                                            
#-----------------------------------------------------
# Searching in "all" parallel with "xargs -n 1 -P {} -I {}"
#-----------------------------------------------------
#***************************************************** 
cd ${output_Dir}
mkdir -p ${output_Dir}/ss_commands

# rfifind 
ls -v ${output_Dir}/*/segment_command/rfifind_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_rfifind_commands.txt
cat ${output_Dir}/ss_commands/ss_rfifind_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""
# prepsubband
ls -v ${output_Dir}/*/segment_command/prepsubband_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_prepsubband_commands.txt
cat ${output_Dir}/ss_commands/ss_prepsubband_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""
# realfft
ls -v ${output_Dir}/*/segment_command/realfft_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_realfft1_commands.txt
bash  ${output_Dir}/ss_commands/ss_realfft1_commands.txt
ls -v ${output_Dir}/*/segment_*/*_realfft.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_realfft2_commands.txt
cat ${output_Dir}/ss_commands/ss_realfft2_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""   
# rednoise  
ls -v ${output_Dir}/*/segment_command/rednoise_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_rednoise1_commands.txt
bash  ${output_Dir}/ss_commands/ss_rednoise1_commands.txt
ls -v ${output_Dir}/*/segment_*/*_rednoise.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_rednoise2_commands.txt
cat ${output_Dir}/ss_commands/ss_rednoise2_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""
# realfft_inv  
ls -v ${output_Dir}/*/segment_command/realfft_inv_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_realfft_inv1_commands.txt
bash  ${output_Dir}/ss_commands/ss_realfft_inv1_commands.txt
ls -v ${output_Dir}/*/segment_*/*_realfft_inv.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_realfft_inv2_commands.txt
cat ${output_Dir}/ss_commands/ss_realfft_inv2_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""
# rm .dat .inf .fft
find ${output_Dir}/*/segment_* -maxdepth 1 -name "*_red.inf" | sort -V | xargs -n1 -I{} -P10 echo "{}" | while read i; do rm -rf "${i:0:-8}".dat "${i:0:-8}".inf "${i:0:-8}".fft; done
# accelsearch
ls -v ${output_Dir}/*/segment_command/accelsearch_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_accelsearch1_commands.txt
bash  ${output_Dir}/ss_commands/ss_accelsearch1_commands.txt
ls -v ${output_Dir}/*/segment_*/*_accelsearch.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_accelsearch2_commands.txt
cat ${output_Dir}/ss_commands/ss_accelsearch2_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""   
# remove .fft
# ls -v ${output_Dir}/*/segment_*/*.fft | xargs -n 1 -P ""${P}"" -I {} rm -rf {}
# ls -v ${output_Dir}/*/segment_*/*_red.dat | xargs -n1 -I{} -P""${P}"" echo "{}" | while read i; do rm -rf "${i:0:-8}".dat "${i:0:-8}".inf; done          
find ${output_Dir}/*/segment_* -maxdepth 1 -name "*.fft" | sort -V | xargs -n1 -P"${P}" -I{} rm -rf {}
# sifiting and folding
ls -v ${output_Dir}/*/segment_command/sifting_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_sifting_commands.txt
bash  ${output_Dir}/ss_commands/ss_sifting_commands.txt
#-----------------------------------------------------
#***************************************************** 

















