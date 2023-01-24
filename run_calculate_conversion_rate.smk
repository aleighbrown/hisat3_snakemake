import os
from pathlib import Path

INPUT_DIR="/SAN/vyplab/alb_projects/data/4su_full_ward_tdp_kd_ipsc/HISAT3N/"
OUTPUT_DIR="/SAN/vyplab/alb_projects/data/4su_full_ward_tdp_kd_ipsc/HISAT3N_perbase_conv/"
INPUT_BED="/SAN/vyplab/vyplab_reference_genomes/annotation/human/GRCh38/gencode.v40_3utr_unique.bed"
conversion_suffix = '.conversion.fake.bed.gz'

basenameBed = Path(INPUT_BED).stem

SAMPLES = [f.replace(conversion_suffix, "") for f in os.listdir(INPUT_DIR) if f.endswith(conversion_suffix)]

rule all:
    input:
        expand(OUTPUT_DIR + "{sample}" + "_" + basenameBed + "_perbase_cov.csv", sample = SAMPLES)


rule calculate_splice_stability:
    input:
        bamfile = INPUT_DIR + "{sample}" + conversion_suffix
    output:
        outputfile = OUTPUT_DIR + "{sample}" + "_" + basenameBed + "_perbase_cov.csv"
    params:
        bed = INPUT_BED
    shell:
        """
        echo {input.bamfile}
        tabix {input.conversion}\
        -R {params.bed} > {outputfile}

        """


# expected TDP43kd_1_8h_controlHumphreyCorticalNeuron-TDP43KDHumphreyCorticalNeuron_annotated_junctionscryptic_clusters_spliced_counts.csv
# output   TDP43kd_1_8h.snpmasked_controlHumphreyCorticalNeuron-TDP43KDHumphreyCorticalNeuron_annotated_junctionscryptic_clusters_spliced_counts.csv