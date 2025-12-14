#!/bin/bash
# Multiple Observations Segment Search with PulsarX 
# @Dejiang Yin, dj.yin@foxmail.com, 2025/12/14
#****************************************************
#-----------------------------------------------------

#-----------------------------------------------------
# The observation containing the different dates, as following
obs_dates=(20190625  20190724  20190725  20190726  20200322  20200323  20200426  20200427)
# The path of your fits data for one source, as following:
file_Path=/home/data/NGC6517
# The path for you to save the searching results, as following:
output_Dir=/home/data/NGC6517/20190625/demo/test1
# The name of your observation source name, as follow:
Source_name=NGC6517
#-----------------------------------------------------
# The path for sifting code, as followiing:
pulsarX_sift=/home/data/NGC6517/20190625/demo/pulsarX_sifting/ACCEL_sift_pulsarx.bash
#-----------------------------------------------------
# Setting for ls *. | xargs -n1 -P{} -I{} ... # ""${P}"",-P, --max-procs=MAX-PROCS  Run up to max-procs processes at a time.
p=10    # only for dedisperse_all_fil & folding
P=50
#-----------------------------------------------------
# The number of fits file for each segment searching of each observation.
files_per_segment=200
# The number of overlapping files between segments
overlap_files=100
#-----------------------------------------------------
# Setting for de-DM
td=1              
fd=2
dms=175
ddm=0.1
ndm=100
#-----------------------------------------------------
# Setting for accelsearch -zmax {} -numharm {} -sigma {}
zmax=20
numharm=16
sigma=2.0
#-----------------------------------------------------
# The command setting for the searching routines,
# dedisperse_all_fil="dedisperse_all_fil -v -t 4 --td --ddplan ${output_Dir}/ddplan.txt -z kadaneF 8 4 zdot --incoherent --format presto --cont --psrfits"
dedisperse_all_fil="dedisperse_all_fil -v -t 4 --td ${td} --fd ${fd} --dms ${dms} --ddm ${ddm} --ndm ${ndm} -z kadaneF 8 4 zdot --incoherent --format presto --cont --psrfits"
realfft="realfft -fwd"
accelsearch="accelsearch -zmax ${zmax} -numharm ${numharm} -sigma ${sigma}"
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
    # Define function to process fits files in segments for "dedisperse_all_fil"                                                                                               
    dedisperse_all_fil_segment() {                                                                                                                                             
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
        echo "cd ${segment_dir} && ${dedisperse_all_fil} -o ${output_name} \$(ls ${File_Path}/*.fits | tail -n +$((start_index + 1)) | head -n $((end_index - start_index + 1))) > ${segment_dir}/${output_name}_dedisperse_all_fil.log"
        echo "\$(ls ${File_Path}/*.fits | tail -n +$((start_index + 1)) | head -n $((end_index - start_index + 1)))" > "${segment_dir}/${output_name}.FileList"        
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
    #*****************************************************                                            
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
        # echo "cd ${segment_dir} && ls ./*.fft | xargs -n1 -I{} echo \"cd ${segment_dir} && ${accelsearch} {}\" >> ${segment_dir}/${output_name}_accelsearch.txt" 
	echo "cd ${segment_dir} && find . -maxdepth 1 -name \"*.fft\" | sort -V | xargs -n1 -I{} echo \"cd ${segment_dir} && ${accelsearch} {}\" >> ${segment_dir}/${output_name}_accelsearch.txt"
    }                                                                                                                                                                                
    #*****************************************************                                            
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
        echo "cd ${segment_dir} && bash ${pulsarX_sift} "                                                                  
    }                                                                                                                     
    #*****************************************************                                            
    #-----------------------------------------------------
    # porferming above defined functions
    #-----------------------------------------------------
    # Process fits files in segments                               
    # dedisperse_all_fil
    for ((i = 0; i < total_segments; i++)); do                     
        dedisperse_all_fil_segment $i >> ${Output_Dir}/dedisperse_all_fil_segment.txt                  
    done                                                                                                                
    # realfft 
    for ((i = 0; i < total_segments; i++)); do           
        realfft_segment $i >> ${Output_Dir}/realfft_segment.txt
    done                                                 
    # accelsearch
    for ((i = 0; i < total_segments; i++)); do                       
        accelsearch_segment $i >> ${Output_Dir}/accelsearch_segment.txt             
    done                                                             
    # sifting
    for ((i = 0; i < total_segments; i++)); do                    
        sifting_segment $i >> ${Output_Dir}/sifting_segment.txt                  
    done  
    #*****************************************************                                            
    #-----------------------------------------------------
    # Others
    # remove the command.txt to segment_command           
    mkdir -p ${Output_Dir}/segment_command                  
    mv ${Output_Dir}/*_segment.txt ${Output_Dir}/segment_command       
    ##-----------------------------------------------------
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
# dedisperse_all_fil 
ls -v ${output_Dir}/*/segment_command/dedisperse_all_fil_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_dedisperse_all_fil_commands.txt
cat ${output_Dir}/ss_commands/ss_dedisperse_all_fil_commands.txt | xargs -n 1 -P ""${p}"" -I {} sh -c ""{}""
# realfft
ls -v ${output_Dir}/*/segment_command/realfft_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_realfft1_commands.txt
bash  ${output_Dir}/ss_commands/ss_realfft1_commands.txt
ls -v ${output_Dir}/*/segment_*/*_realfft.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_realfft2_commands.txt
cat ${output_Dir}/ss_commands/ss_realfft2_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""   
# accelsearch
ls -v ${output_Dir}/*/segment_command/accelsearch_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_accelsearch1_commands.txt
bash  ${output_Dir}/ss_commands/ss_accelsearch1_commands.txt
ls -v ${output_Dir}/*/segment_*/*_accelsearch.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_accelsearch2_commands.txt
cat ${output_Dir}/ss_commands/ss_accelsearch2_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""   
# remove .fft
find ${output_Dir}/*/segment_* -maxdepth 1 -name "*.fft" | sort -V | xargs -n1 -P"${P}" -I{} rm -rf {}
# sifiting and folding
ls -v ${output_Dir}/*/segment_command/sifting_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_sifting_commands.txt
cat  ${output_Dir}/ss_commands/ss_sifting_commands.txt | xargs -n 1 -P ""${p}"" -I {} sh -c ""{}""
#-----------------------------------------------------
#***************************************************** 
