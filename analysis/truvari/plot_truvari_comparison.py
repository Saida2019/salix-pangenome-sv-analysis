import matplotlib.pyplot as plt
from matplotlib_venn import venn2

# -----------------------------
# Input data
# -----------------------------

sv_types = ["DEL", "INS", "INV", "DUP"]

linear_type_counts = [50723, 3752, 143, 1]
graph_type_counts  = [31511, 2356, 0, 0]

size_bins = ["50-99 bp", "100-999 bp", "1-9.9 kb", ">=10 kb"]
linear_size_counts = [18644, 28720, 6848, 407]
graph_size_counts  = [12998, 20869, 0, 0]

linear_only = 22099
graph_only = 1410
shared = 32419

metrics = ["Precision", "Recall", "F1"]
metric_values = [0.9583197848000237, 0.5946402039730726, 0.7338958845361198]

linear_color = "#4C72B0"
graph_color = "#DD8452"

# -----------------------------
# Helper function to label bars
# -----------------------------

def add_labels(ax, bars):
    for bar in bars:
        height = bar.get_height()
        ax.text(
            bar.get_x() + bar.get_width()/2,
            height,
            f"{int(height):,}",
            ha='center',
            va='bottom',
            fontsize=9
        )


# -----------------------------
# Figure 1: SV type distribution
# -----------------------------

fig, ax = plt.subplots(figsize=(7,5))

x = range(len(sv_types))
width = 0.35

bars1 = ax.bar(
    [i - width/2 for i in x],
    linear_type_counts,
    width,
    label="Linear",
    color=linear_color
)

bars2 = ax.bar(
    [i + width/2 for i in x],
    graph_type_counts,
    width,
    label="Graph",
    color=graph_color
)

ax.set_xticks(list(x))
ax.set_xticklabels(sv_types)
ax.set_ylabel("Number of SVs")
ax.set_title("SV type distribution")
ax.legend(frameon=False)

add_labels(ax, bars1)
add_labels(ax, bars2)

plt.tight_layout()
plt.savefig("figure1_sv_type_distribution.png", dpi=300)
plt.close()


# -----------------------------
# Figure 2: SV length distribution
# -----------------------------

fig, ax = plt.subplots(figsize=(7,5))

x = range(len(size_bins))

bars1 = ax.bar(
    [i - width/2 for i in x],
    linear_size_counts,
    width,
    label="Linear",
    color=linear_color
)

bars2 = ax.bar(
    [i + width/2 for i in x],
    graph_size_counts,
    width,
    label="Graph",
    color=graph_color
)

ax.set_xticks(list(x))
ax.set_xticklabels(size_bins, rotation=20)
ax.set_ylabel("Number of SVs")
ax.set_title("SV length distribution")
ax.legend(frameon=False)

add_labels(ax, bars1)
add_labels(ax, bars2)

plt.tight_layout()
plt.savefig("figure2_sv_length_distribution.png", dpi=300)
plt.close()


# -----------------------------
# Figure 3: Venn diagram
# -----------------------------

plt.figure(figsize=(6,6))

venn = venn2(
    subsets=(linear_only, graph_only, shared),
    set_labels=("Linear SVs", "Graph SVs")
)

venn.get_patch_by_id('10').set_color(linear_color)
venn.get_patch_by_id('01').set_color(graph_color)
venn.get_patch_by_id('11').set_color("#937860")

for patch in venn.patches:
    if patch:
        patch.set_alpha(0.6)

plt.title("Overlap between linear and graph SV callsets")
plt.tight_layout()
plt.savefig("figure3_sv_overlap_venn.png", dpi=300)
plt.close()


# -----------------------------
# Figure 4: Benchmark metrics
# -----------------------------

plt.figure(figsize=(6,5))

bars = plt.bar(metrics, metric_values, color="#55A868")

plt.ylim(0,1.05)
plt.ylabel("Value")
plt.title("Benchmarking metrics (Truvari)")

for bar in bars:
    height = bar.get_height()
    plt.text(
        bar.get_x() + bar.get_width()/2,
        height,
        f"{height:.2f}",
        ha='center',
        va='bottom'
    )

plt.tight_layout()
plt.savefig("figure4_truvari_metrics.png", dpi=300)
plt.close()

print("Figures generated successfully.")
