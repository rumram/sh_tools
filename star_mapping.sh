#!/bin/bash

# Warning if no arguments provided
if [ $# -eq 0 ]
        then
        echo "No arguments provided!"
        exit 1
fi

Help()
{
   echo "Usage: bash star_mapping.sh [-s|r|g|f|i|t|h]"
   echo "-h     Display help."
   echo "-s     Provide STAR path."
   echo "-r     Provide reads path."
   echo "-g     Provide GTF file."
   echo "-f     Provide index file."
   echo "-i     Provide index path."
   echo "-t     Select if trimmed (T) or untrimmed (U) reads."
   echo
}

# Get the options
while getopts "hs:r:g:f:i:t:" option; do
   case $option in
      h) # STAR path
         Help
         exit;;
      s) # STAR path
         STAR=$OPTARG;;
      r) # Reads directory
         READS=$OPTARG;;
      g) # GTF file
         GTF=$OPTARG;;
      f) # Index file
         IDX_FILE=$OPTARG;;
      i) # Index
         INDEX=$OPTARG;;
      t) # if trimmed reads
         TRIM=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

# Create output directory if not already there.
if [ "$GTF" ] && [ "$IDX_FILE" ] && [ -z "$INDEX" ]
	then
	echo "No pre-built index. The index will be generated from index file and corresponding GTF file."
        if [ ! -d Star_index ]
               then
                 mkdir Star_index

                 $STAR --runThreadN 60 \
                 --runMode genomeGenerate \
                 --genomeDir Star_index \
                 --genomeFastaFiles $IDX_FILE \
                 --sjdbGTFfile $GTF \
                 --sjdbOverhang 150

	echo "Index created proceed to mapping."
       fi

elif [ "$INDEX" ] && [ -z "$GTF" ] && [ -z "$IDX_FILE" ]
	then
	echo "Found pre-built index."

else
	echo "Set pre-built index path or index file with corresponding GTF."
	exit 1
fi

# Create output directory if not already there.
if [ ! -d Star_mapped ]
	then
        mkdir Star_mapped
fi

# Run STAR mapping on all provided samples.
ulimit -n 4096


if [ "${TRIM}" = "U" ] && [ "$INDEX" ]
	then
	for i in $(find $READS/*.fastq.gz -type f -printf "%f\n")
	do
		echo "Mapping sample" "${i%%_*}"
		$STAR --genomeDir $INDEX \
		--runMode alignReads \
		--readFilesCommand gunzip -c \
		--readFilesIn $READS/"${i%%_*}"_1.fastq.gz $READS/"${i%%_*}"_2.fastq.gz \
		--runThreadN 60 \
		--outSAMtype BAM SortedByCoordinate \
		--outFileNamePrefix Star_mapped/"${i%%_*}"
	done

elif [ "${TRIM}" = "U" ] && [ -z "$INDEX" ]
        then
        for i in $(find $READS/*.fastq.gz -type f -printf "%f\n")
        do
                echo "Mapping sample" "${i%%_*}"
                $STAR --genomeDir $PWD/Star_index \
                --runMode alignReads \
                --readFilesCommand gunzip -c \
                --readFilesIn $READS/"${i%%_*}"_1.fastq.gz $READS/"${i%%_*}"_2.fastq.gz \
                --runThreadN 60 \
                --outSAMtype BAM SortedByCoordinate \
                --outFileNamePrefix Star_mapped/"${i%%_*}"
        done

#KO1-3_1_1.fastq.gz
#KO1-3_1.fastq.gz
#rawData2/KO1-3_1.fastq.gz_1.fastq.gz
#"${i%%.*}

elif [ "${TRIM}" = "T" ] && [ "$INDEX" ]
	then
        for i in $(find $READS/* -type d -printf "%f\n")
        do
                echo "Mapping sample" $i
                $STAR --genomeDir $INDEX  \
                --runMode alignReads \
                --readFilesCommand gunzip -c \
                --readFilesIn $READS/"${i}"/"${i}"_1-trimmed.fastq.gz $READS/"${i}"/"${i}"_2-trimmed.fastq.gz \
                --runThreadN 60 \
                --outSAMtype BAM SortedByCoordinate \
                --outFileNamePrefix Star_mapped/"${i}"
	done

elif [ "${TRIM}" = "T" ] && [ -z "$INDEX" ]
        then
        for i in $(find $READS/* -type d -printf "%f\n")
        do
                echo "Mapping sample" $i
                $STAR --genomeDir $PWD/Star_index  \
                --runMode alignReads \
                --readFilesCommand gunzip -c \
                --readFilesIn $READS/"${i}"/"${i}"_1-trimmed.fastq.gz $READS/"${i}"/"${i}"_2-trimmed.fastq.gz \
                --runThreadN 60 \
                --outSAMtype BAM SortedByCoordinate \
                --outFileNamePrefix Star_mapped/"${i}"
        done

else
	exit 1
fi

unset STAR
unset TRIM
unset READS
unset IDX_FILE
unset GTF
unset INDEX

