#!/bin/bash
#SBATCH -A naiss2025-22-1574
#SBATCH -p shared
#SBATCH -t 96:00:00
#SBATCH -J salix_vg_map
#SBATCH --cpus-per-task=72
#SBATCH --array=1-80%4
#SBATCH -o /cfs/klemming/projects/supr/naiss2025-23-666/Saida/Scripts/vcf_output/PANGENOME/remapping/logs/%x_%A_%a.out
#SBATCH -e /cfs/klemming/projects/supr/naiss2025-23-666/Saida/Scripts/vcf_output/PANGENOME/remapping/logs/%x_%A_%a.err
#SBATCH --mail-user="my_email" #change
#SBATCH --mail-type=END,FAIL

set -euo pipefail
module load bioinfo-tools
module load vg/1.48.0

# ---- Graph workdir  ----
WORK="/cfs/klemming/projects/supr/naiss2025-23-666/Saida/Scripts/vcf_output/PANGENOME/remapping"
XG="$WORK/salix.sv.xg"
GCSA="$WORK/salix.sv.gcsa"

# ---- Sample list location  ----
SAMPLES_TSV="/cfs/klemming/projects/supr/naiss2025-23-666/Saida/Scripts/vcf_output/PANGENOME/remapping/samples_80_part_00.tsv"

# ---- Output ----
OUTDIR="$WORK/mapping_gam"
mkdir -p "$OUTDIR" "$WORK/logs"

THREADS=8

echo "== Sanity checks =="
test -f "$XG" || (echo "Missing XG: $XG" && exit 1)
test -f "$GCSA" || (echo "Missing GCSA: $GCSA" && exit 1)
test -f "$SAMPLES_TSV" || (echo "Missing samples.tsv: $SAMPLES_TSV" && exit 1)

LINE="$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES_TSV")"
if [[ -z "${LINE}" ]]; then
  echo "No line found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID} in $SAMPLES_TSV"
  exit 1
fi

SAMPLE_ID="$(echo "$LINE" | cut -f1)"
R1="$(echo "$LINE" | cut -f2)"
R2="$(echo "$LINE" | cut -f3)"

echo "== Task info =="
echo "Array task: ${SLURM_ARRAY_TASK_ID}"
echo "Sample: ${SAMPLE_ID}"
echo "R1: ${R1}"
echo "R2: ${R2}"
echo "Threads: ${THREADS}"

test -f "$R1" || (echo "Missing R1: $R1" && exit 1)
test -f "$R2" || (echo "Missing R2: $R2" && exit 1)

OUTGAM="$OUTDIR/${SAMPLE_ID}.vs_graph.gam"

echo "== Mapping reads to graph with vg map =="
vg map -x "$XG" -g "$GCSA" \
  -f "$R1" -f "$R2" \
  -t "$THREADS" \
  > "$OUTGAM"

echo "== Compress GAM =="
gzip -f "$OUTGAM"

echo "== Done =="
ls -lh "$OUTGAM"
