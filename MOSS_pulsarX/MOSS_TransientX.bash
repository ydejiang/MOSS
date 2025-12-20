#!/bin/bash
# Multiple Observations Segment Search with TransientX
# @Dejiang Yin, dj.yin@foxmail.com, 2025/12/14
#****************************************************
#-----------------------------------------------------

#-----------------------------------------------------
# The observation containing the different dates, as following
obs_dates=(20190625  20190724)
# The path of your fits data for one source, as following:
file_Path=/home/data/NGC6517
# The path for you to save the searching results, as following:
output_Dir=/home/data/NGC6517/20190625/demo/test2
# The name of your observation source name, as follow:
Source_name=NGC6517
#-----------------------------------------------------
# Setting for ls *. | xargs -n1 -P{} -I{} ... # ""${P}"",-P, --max-procs=MAX-PROCS  Run up to max-procs processes at a time.
P=15
#-----------------------------------------------------
# The number of fits file for each segment searching of each observation.
files_per_segment=10000000
# The number of overlapping files between segments
overlap_files=0
#-----------------------------------------------------
# The command setting for the searching routines
transientx_fil="transientx_fil -v -t 4 --zapthre 3.0 --fd 1 --overlap 0.1 --ddplan ${output_Dir}/ddplan_TransientX.txt --thre 7 --maxw 0.1 --snrloss 0.1 -l 2.0 --drop -z kadaneF 8 4 zdot --cont --psrfits"
replot_fil="replot_fil -v -t 4 --zapthre 3.0 --td 1 --fd 1 --dmcutoff 3 --widthcutoff 0.1 --snrcutoff 7 --snrloss 0.1 --zap --zdot --kadane 8 4 7 --clean --psrfits"
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
    # Define function to process fits files in segments for "transientx_fil"                                                                                               
    transientx_fil_segment() {                                                                                                                                             
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
        echo "cd ${segment_dir} && ${transientx_fil} -o ${output_name} \$(ls ${File_Path}/*.fits | tail -n +$((start_index + 1)) | head -n $((end_index - start_index + 1))) > ${segment_dir}/${output_name}_transientx_fil.log"        
    } 
    #----------------------------------------------------- 
    # Define function to process fits files in segments for "replot_fil"                                                                                       
    replot_fil_segment() {                                                                                                                                     
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
        echo "cd ${segment_dir} && ${replot_fil} --candfile ${output_name}*.cands  \$(ls ${File_Path}/*.fits | tail -n +$((start_index + 1)) | head -n $((end_index - start_index + 1))) > ${segment_dir}/${output_name}_replot_fil.log"        
    }  
    #-----------------------------------------------------
    # porferming above defined functions
    #-----------------------------------------------------
    # Process fits files in segments                               
    # transientx_fil
    for ((i = 0; i < total_segments; i++)); do                     
        transientx_fil_segment $i >> ${Output_Dir}/transientx_fil_segment.txt                  
    done                                                                                                                
    # replot_fil
    for ((i = 0; i < total_segments; i++)); do           
        replot_fil_segment $i >> ${Output_Dir}/replot_fil_segment.txt
    done                                                 
    #-----------------------------------------------------
    # Others
    # remove the command.txt to segment_command           
    mkdir -p ${Output_Dir}/segment_command                  
    mv ${Output_Dir}/*_segment.txt ${Output_Dir}/segment_command       
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
# transientx_fil 
ls -v ${output_Dir}/*/segment_command/transientx_fil_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_transientx_fil_commands.txt
cat ${output_Dir}/ss_commands/ss_transientx_fil_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""
# replot_fil
ls -v ${output_Dir}/*/segment_command/replot_fil_segment.txt | xargs -n 1 -I {} cat {} >> ${output_Dir}/ss_commands/ss_replot_fil_commands.txt
cat ${output_Dir}/ss_commands/ss_replot_fil_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""
#-----------------------------------------------------
#***************************************************** 
