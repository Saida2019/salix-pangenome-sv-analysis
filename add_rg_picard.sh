#!/bin/bash -l
#SBATCH -A project_name
#SBATCH -J addRG_array_picard
#SBATCH -p shared
#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH -t 12:00:00
#SBATCH --output=logs/RG_%A_%a.out
#SBATCH --mail-user=email@domain.com
#SBATCH --mail-type=END,FAIL
#SBATCH --array=0-80%10  # we can adjust to number of BAMs (excluding header)

set -euo pipefail

module load java/17.0.4
module load picard/3.3.0

BAM_FILES_DIR="results/bwa"
BAM_RG_DIR="results/bwa_rg"
SAMPLE_LIST="data/samples_bam.txt"

mkdir -p "$BAM_RG_DIR" logs

LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 2))p" "$SAMPLE_LIST")

read BAM SM LB PL PU PM PI <<< "$LINE"

INPUT_BAM="$BAM_FILES_DIR/$BAM"
OUT_BAM="$BAM_RG_DIR/${BAM%.bam}.RGID.bam"

if [[ ! -f "$INPUT_BAM" ]]; then
    echo "ERROR: Input BAM not found: $INPUT_BAM"
    exit 1
fi

echo "Processing $BAM with sample $SM"

java -jar "$EBROOTPICARD/picard.jar" AddOrReplaceReadGroups \
    I="$INPUT_BAM" \
    O="$OUT_BAM" \
    RGID="$SM" \
    RGLB="$LB" \
    RGPL="$PL" \
    RGPU="$PU" \
    RGSM="$SM" \
    RGPM="$PM" \
    RGPI="$PI" \
    CREATE_INDEX=true

echo "Finished $BAM"

