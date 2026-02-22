#!/bin/bash -l
#SBATCH -A project_name
#SBATCH -J bwa_mapping_array
#SBATCH -p shared
#SBATCH -N 1                
#SBATCH --cpus-per-task=8   
#SBATCH --mem=64G           
#SBATCH -t 12:00:00
#SBATCH --output=logs/bwa_%A_%a.out
#SBATCH --mail-user=email@domain.com
#SBATCH --mail-type=END,FAIL
#SBATCH --array=0-80%10   # we can adjust to number of samples

set -euo pipefail

# Load modules
module load bwa/0.7.18
module load samtools/1.20

# Directories
RAW_FASTQ_DIR="data/raw"
BWA_RESULTS_DIR="results/bwa"
REFERENCE_FASTA="ref/genome.fasta"
SAMPLE_LIST="sample/samples.txt"  #File with sample names (one per line)

mkdir -p "$BWA_RESULTS_DIR" "logs"

# Select sample based on SLURM_ARRAY_TASK_ID
ACC=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$SAMPLE_LIST")
echo "Processing sample: $ACC"

# Node-local TMPDIR
TMPDIR="$PDC_TMP/${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$TMPDIR"
cd "$TMPDIR"

# Locate paired FASTQ files
R1=$(find "$RAW_FASTQ_DIR" -type f -name "${ACC}_*_R1_001.fastq.gz" | head -n1)
R2=$(find "$RAW_FASTQ_DIR" -type f -name "${ACC}_*_R2_001.fastq.gz" | head -n1)

if [[ -z "$R1" || -z "$R2" ]]; then
    echo "ERROR: FASTQ files missing for $ACC"
    exit 1
fi

# Copy FASTQ to node-local TMP
cp "$R1" "$TMPDIR/"
cp "$R2" "$TMPDIR/"

R1_FILE=$(basename "$R1")
R2_FILE=$(basename "$R2")
BAM_OUT="${ACC}.sorted.bam"

# Check if files exist and are non-empty
if [[ ! -f "$R1_FILE" || ! -f "$R2_FILE" ]]; then
    echo "ERROR: One or both FASTQ files missing in TMPDIR: $R1_FILE, $R2_FILE"
    exit 1
fi

if [[ ! -s "$R1_FILE" || ! -s "$R2_FILE" ]]; then
    echo "ERROR: One or both FASTQ files are empty in TMPDIR: $R1_FILE, $R2_FILE"
    exit 1
fi

# Run BWA MEM -> samtools view -> samtools sort
bwa mem -M -t ${SLURM_CPUS_PER_TASK} "$REFERENCE_FASTA" "$R1_FILE" "$R2_FILE" | \
samtools view -b -@ ${SLURM_CPUS_PER_TASK} - | \
samtools sort -@ ${SLURM_CPUS_PER_TASK}  -m 1G -T "$TMPDIR/sort_tmp" -o "$BAM_OUT" -

# Index BAM
samtools index "$BAM_OUT"

# Move results to output directory
mv "$BAM_OUT" "$BWA_RESULTS_DIR/"
mv "${BAM_OUT}.bai" "$BWA_RESULTS_DIR/"

# Clean TMP
rm -rf "$TMPDIR"

echo "Finished mapping: $ACC"
