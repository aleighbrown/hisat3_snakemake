
import os
configfile: "config/config.yaml"
cluster_config: "config/cluster.yaml"
include: "helpers.py"

#make sure the output folder for STAR exists before running anything
hisat_outdir = get_output_dir(config["project_top_level"], config['histat3n_output_folder'])
os.system("mkdir -p {0}".format(hisat_outdir))

merged_outdir = get_output_dir(config['project_top_level'], config['merged_fastq_folder'])

SAMPLES = pd.read_csv(config["sampleCSVpath"], sep = ",")
SAMPLES = SAMPLES.replace(np.nan, '', regex=True)

SAMPLE_NAMES = SAMPLES['sample_name'].tolist()


GENOME_DIR = "/SAN/vyplab/vyplab_reference_genomes/hisat-3n/human/raw"
GENOME_FA = config['fasta']
CHRMSIZES = config['fasta_sizes']
bedGraph = '/SAN/vyplab/alb_projects/tools/bedGraphToBigWig'

rule all_makeBW:
    input:
        expand(hisat_outdir + "{name}.count.plus.bw", name = SAMPLE_NAMES),
        expand(hisat_outdir + "{name}.count.minus.bw", name = SAMPLE_NAMES),
        expand(hisat_outdir + "{name}.rate.plus.bw", name = SAMPLE_NAMES),
        expand(hisat_outdir + "{name}.rate.minus.bw",name = SAMPLE_NAMES)

rule split_conversion:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        hisat_outdir + "{name}.conversion.tsv"
    output:
        temp(hisat_outdir + "{name}.+.txt"),
        temp(hisat_outdir + "{name}.-.txt")
    params:
        outputPrefix = os.path.join(hisat_outdir + "{name}."),
    shell:
        """
        source splitAwk.sh {input} {params.outputPrefix}
        """

rule split_toBedGraphRatePlus:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        plus = hisat_outdir + "{name}.+.txt",
    output:
        plusR = temp(hisat_outdir + "{name}.plus.rate.bedgraph")
    shell:
        """
        source rateAwk.sh {input.plus} {output.plusR}
        """

rule split_toBedGraphRateMinus:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        minus = hisat_outdir + "{name}.-.txt",
    output:
        minusR = temp(hisat_outdir + "{name}.minus.rate.bedgraph")
    shell:
        """
        source rateAwk.sh {input.minus} {output.minusR}
        """

rule split_toBedGraphCountPlus:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        plus = hisat_outdir + "{name}.+.txt"
    output:
        plusC = temp(hisat_outdir + "{name}.plus.count.bedgraph")
    shell:
        """
        source countAwk.sh {input.plus} {output.plusC}
        """

rule split_toBedGraphCountMinus:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        minus = hisat_outdir + "{name}.-.txt"
    output:
        minusC = temp(hisat_outdir + "{name}.plus.count.bedgraph")
    shell:
        """
        source countAwk.sh {input.minus} {output.minusC}
        """

rule sortBedGraph:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        plusC = hisat_outdir + "{name}.plus.count.bedgraph",
        minusC = hisat_outdir + "{name}.minus.count.bedgraph",
        plusR = hisat_outdir + "{name}.plus.rate.bedgraph",
        minusR = hisat_outdir + "{name}.minus.rate.bedgraph"
    output:
        plusC = temp(hisat_outdir + "{name}.plus.count.sorted.bedgraph"),
        minusC = temp(hisat_outdir + "{name}.minus.count.sorted.bedgraph"),
        plusR = temp(hisat_outdir + "{name}.plus.rate.sorted.bedgraph"),
        minusR = temp(hisat_outdir + "{name}.minus.rate.sorted.bedgraph")
    shell:
        """
        LC_COLLATE=C sort -k1,1 -k2,2n {input.plusC} > {output.plusC}
        LC_COLLATE=C sort -k1,1 -k2,2n {input.minusC} > {output.minusC}
        LC_COLLATE=C sort -k1,1 -k2,2n {input.plusR} > {output.plusR}
        LC_COLLATE=C sort -k1,1 -k2,2n {input.minusR} > {output.minusR}
        """

rule sortBedGraphPlusCount:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        plusC = hisat_outdir + "{name}.plus.count.bedgraph"
    output:
        plusC = temp(hisat_outdir + "{name}.plus.count.sorted.bedgraph")
    shell:
        """
        LC_COLLATE=C sort -k1,1 -k2,2n {input.plusC} > {output.plusC}
        """

rule sortBedGraphMinusCount:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        minusC = hisat_outdir + "{name}.minus.count.bedgraph"
    output:
        minusC = temp(hisat_outdir + "{name}.minus.count.sorted.bedgraph")
    shell:
        """
        LC_COLLATE=C sort -k1,1 -k2,2n {input.minusC} > {output.minusC}
        """

rule sortBedGraphPlusRate:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        plusR = hisat_outdir + "{name}.plus.rate.bedgraph"
    output:
        plusR = temp(hisat_outdir + "{name}.plus.rate.sorted.bedgraph")
    shell:
        """
        LC_COLLATE=C sort -k1,1 -k2,2n {input.plusR} > {output.plusR}
        """

rule bedGraphtoBWPlusCount:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        plusC = hisat_outdir + "{name}.plus.count.sorted.bedgraph"
    output:
        plusC = hisat_outdir + "{name}.count.plus.bw"
    shell:
        """
        /SAN/vyplab/alb_projects/tools/bedGraphToBigWig {input.plusC} \
        {CHRMSIZES} {output.plusC}
        """

rule bedGraphtoBWMinusCount:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        minusC = hisat_outdir + "{name}.minus.count.sorted.bedgraph"
    output:
        minusC = hisat_outdir + "{name}.count.minus.bw"
    shell:
        """
        /SAN/vyplab/alb_projects/tools/bedGraphToBigWig {input.minusC} \
        {CHRMSIZES} {output.minusC}
        """
rule bedGraphtoBWPlusRate:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        plusR = hisat_outdir + "{name}.plus.rate.sorted.bedgraph"
    output:
        plusR = hisat_outdir + "{name}.rate.plus.bw"
    shell:
        """
        /SAN/vyplab/alb_projects/tools/bedGraphToBigWig {input.plusR} \
        {CHRMSIZES} {output.plusR}
        """

rule bedGraphtoBWMinusRate:
    wildcard_constraints:
        sample="|".join(SAMPLE_NAMES)
    input:
        minusR = hisat_outdir + "{name}.minus.rate.sorted.bedgraph"
    output:
        minusR = hisat_outdir + "{name}.rate.minus.bw"
    shell:
        """
        /SAN/vyplab/alb_projects/tools/bedGraphToBigWig {input.minusR} \
        {CHRMSIZES} {output.minusR}
        """