#!/bin/bash -l
#SBATCH -A project_name
#SBATCH -J markdup_array_picard
#SBATCH -p shared
#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH -t 12:00:00
#SBATCH --output=logs/markdup_%A_%a.out
#SBATCH --mail-user=email@domain.com
#SBATCH --mail-type=END,FAIL
#SBATCH --array=0-80%10   # we can adjust to number of BAMs 

set -euo pipefail

module load java/17.0.4
module load picard/3.3.0

# Input BAMs (after AddOrReplaceReadGroups)
BAM_RG_DIR="results/bwa_rg"

# Output directory for deduplicated BAMs + metrics
BAM_DEDUP_DIR="results/bwa_rg_dedup"
mkdir -p "$BAM_DEDUP_DIR" logs

# Sample list (header + columns)
# bam_filename  SM  LB  PL  PU  PM  PI
SAMPLE_LIST="data/samples_bam.txt"

# Skip header
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 2))p" "$SAMPLE_LIST")
if [[ -z "${LINE:-}" ]]; then
  echo "ERROR: No line found in SAMPLE_LIST for task ${SLURM_ARRAY_TASK_ID}"
  exit 1
fi

# We keep the same table format as RG script
read -r BAM SM LB PL PU PM PI <<< "$LINE"

IN_BAM="$BAM_RG_DIR/$BAM"
BASE=$(basename "$BAM" .bam)

OUT_BAM="$BAM_DEDUP_DIR/${BASE}.dedup.bam"
METRICS="$BAM_DEDUP_DIR/${BASE}.dup_metrics.txt"

if [[ ! -f "$IN_BAM" ]]; then
  echo "ERROR: Input BAM not found: $IN_BAM"
  exit 1
fi

echo "Running MarkDuplicates on: $IN_BAM"

java -jar "$EBROOTPICARD/picard.jar" MarkDuplicates \
  INPUT="$IN_BAM" \
  OUTPUT="$OUT_BAM" \
  METRICS_FILE="$METRICS" \
  CREATE_INDEX=true \
  VALIDATION_STRINGENCY=SILENT

echo "Finished: $OUT_BAM"



