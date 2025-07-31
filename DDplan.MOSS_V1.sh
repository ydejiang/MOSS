#!/bin/bash
# Multiple Observations Segment Search 
# @Dejiang Yin, dj.yin@foxmail.com, 20240616
#****************************************************
#-----------------------------------------------------

#-----------------------------------------------------
# The observation containing the different dates, as following
obs_dates=(20231108)
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
files_per_segment=400
# The number of overlapping files between segments
overlap_files=200 
#-----------------------------------------------------
## DDplan.py *
#----------------------------------------------------------------------------------------------------
# The parameters for DDplan.py to search for pulsars!
loDM=0                          #  [-l loDM, --loDM=loDM]          : Low DM to search   (default = 0 pc cm-3)
hiDM=250                        #  [-d hiDM, --hiDM=HIDM]          : High DM to search  (default = 1000 pc cm-3)
fctr=1250                       #  [-f fctr, --fctr=fctr]          : Center frequency   (default = 1400MHz)
BW=500                          #  [-b BW, --bw=bandwidth]         : Bandwidth in MHz   (default = 300MHz)
chan=4096                       #  [-n #chan, --numchan=#chan]     : Number of channels (default = 1024)
dt=0.000049152                  #  [-t dt, --dt=dt]                : Sample time (s)    (default = 0.000064 s)
nsub=1024                       #  [-s #subbands, --subbands=nsub] : Number of subbands (default = #chan)

python ydj-DDplan.py -l ${loDM} -d ${hiDM} -f ${fctr} -b ${BW} -n ${chan} -t ${dt} -s ${nsub} -o ${Source_name} -w ${Source_name}
rm -rf ${Source_name}_de-DM_MOSS.comd
python dedisp_${Source_name}.py
#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------
# Setting for accelsearch -zmax {} -numharm {} -sigma {}
zmax=520
numharm=32
sigma=2.0
#-----------------------------------------------------
# The command setting for the searching routines,
rfifind="rfifind -time 2.0 -ignorechan 680:810 "
# prepsubband="prepsubband -nobary -nsub ${nsub} -lodm ${lodm} -dmstep ${dmstep} -numdms ${numdms} -downsamp ${downsamp} -ignorechan 680:810  "
realfft="realfft -fwd "
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
        # echo "cd ${segment_dir} && ${prepsubband} -o ${output_name} -mask ${output_name}_rfifind.mask \$(ls ${File_Path}/*.fits | tail -n +$((start_index + 1)) | head -n $((end_index - start_index + 1))) > ${segment_dir}/${output_name}_prepsubband.log"  
	prepsubband_commands_file="${Source_name}_de-DM_MOSS.comd"
        if [ -f "$prepsubband_commands_file" ]; then
                # Initialize a log counter
                log_counter=1
                # Read each line from prepsubband.txt and execute the command
                while IFS= read -r prepsubband_cmd; do
                        # echo "Executing in ${segment_dir}: ${prepsubband_cmd}"
                        # Execute the prepsubband command in the current segment directory
                        echo "cd ${segment_dir} && ${prepsubband_cmd} -o ${output_name} -mask ${output_name}_rfifind.mask \$(ls ${File_Path}/*.fits | tail -n +$((start_index + 1)) | head -n $((end_index - start_index + 1))) > ${segment_dir}/${output_name}_prepsubband_${log_counter}.log"
                        # Increment the log counter for each command
                        log_counter=$((log_counter + 1))
                done < "$prepsubband_commands_file"
        else
                echo "File $prepsubband_commands_file does not exist."
        fi
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
    ##-----------------------------------------------------
    # If you just want to test this shell scripts to generate the searching commands, the following can be commment.
    ##-----------------------------------------------------
    ##-----------------------------------------------------
    #*************************************************************************************************************                                          
    # DDplan.py files
    mv ${Source_name}_de-DM_MOSS.comd ${Output_Dir}/segment_command
    mv dedisp_${Source_name}.py ${Output_Dir}/segment_command
    mv ${Source_name}.eps ${Output_Dir}/segment_command
    # rfidind                                                                                                                                               
    cat ${Output_Dir}/segment_command/rfifind_segment.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""                                                       
    #*************************************************************************************************************                                          
    # prepsubband                                                                                                                                           
    cat ${Output_Dir}/segment_command/prepsubband_segment.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""                                                   
    #*************************************************************************************************************                                          
    # realfft                                                                                                                                               
    bash  ${Output_Dir}/segment_command/realfft_segment.txt                                                                                                    
    ls -v ${Output_Dir}/segment_*/*_realfft.txt | xargs -n1 -I{} cat {} >> ${Output_Dir}/segment_command/all_segment_realfft_commands.txt                      
    cat ${Output_Dir}/segment_command/all_segment_realfft_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""                                          
    #*************************************************************************************************************                                          
    # accelsearch                                                                                                                                           
    bash  ${Output_Dir}/segment_command/accelsearch_segment.txt                                                                                                
    ls -v ${Output_Dir}/segment_*/*_accelsearch.txt | xargs -n1 -I{} cat {} >> ${Output_Dir}/segment_command/all_segment_accelsearch_commands.txt              
    cat ${Output_Dir}/segment_command/all_segment_accelsearch_commands.txt | xargs -n 1 -P ""${P}"" -I {} sh -c ""{}""                                      
    #*************************************************************************************************************                                          
    # remove .fft                                                                                                                                           
    find ${Output_Dir}/segment_* -maxdepth 1 -name "*.fft" | sort -V | xargs -n1 -P"${P}" -I{} rm -rf {}
    #*************************************************************************************************************                                          
    # sifting                                                                                                                                               
    bash  ${Output_Dir}/segment_command/sifting_segment.txt                                                                                                    
    #*************************************************************************************************************  

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
#***************************************************** 
                                       
