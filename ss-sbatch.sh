#!/bin/bash
#SBATCH -o ydj.%j.out
#SBATCH -p cpu-liminghui
#SBATCH -J ydj-m13-ss
#SBATCH -N 1
#SBATCH -n 15

sh /groups/galaxy/home/yindejiang/presto_search/MOSS_v2.sh 
