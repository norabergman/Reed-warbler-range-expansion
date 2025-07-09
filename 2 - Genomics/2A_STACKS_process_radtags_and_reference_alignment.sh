### STACKS process_radtags ###

# Running process_radtags for each lane of each plate separately
# The input files (raw sequence files) are available on NCBI SRA (BioProject PRJNA1217894).
# Notice option -t (truncate) to make all reads of length 91 bp!

module load stacks

process_radtags -f ../raw/sequence_archive_lane1.fastq.gz \
-o ../cleaned_with_fgx_control/2017_lane1/ -b ../info/2017_barcodes -e sbfI -r -c -q -t 91

process_radtags -f ../raw/sequence_archive_lane2.fastq.gz \
-o ../cleaned_with_fgx_control/2017_lane2/ -b ../info/2017_barcodes -e sbfI -r -c -q -t 91

process_radtags -f ../raw/2021RADsequences_plate1_lane1.fastq.gz \
-o ../cleaned_with_fgx_control/2021_plate1_lane1/ -b ../info/2021_plate1_barcodes -e sbfI -r -c -q -t 91

process_radtags -f ../raw/2021RADsequences_plate1_lane2.fastq.gz \
-o ../cleaned_with_fgx_control/2021_plate1_lane2/ -b ../info/2021_plate1_barcodes -e sbfI -r -c -q -t 91

process_radtags -f ../raw/2021RADsequences_plate2_lane1.fastq.gz \
-o ../cleaned_with_fgx_control/2021_plate2_lane1/ -b ../info/2021_plate2_barcodes -e sbfI -r -c -q -t 91

process_radtags -f ../raw/2021RADsequences_plate2_lane2.fastq.gz \
-o ../cleaned_with_fgx_control/2021_plate2_lane2/ -b ../info/2021_plate2_barcodes -e sbfI -r -c -q -t 91


### Combining the two lanes for each plate ###

# Creating a list of sample names on each plate
# Run code in the folder with the fq.gz files
ls | sed -n 's/\.fq.gz$//p' > ../../info/namelist_2017
ls | sed -n 's/\.fq.gz$//p' > ../../info/namelist_2021_plate1
ls | sed -n 's/\.fq.gz$//p' > ../../info/namelist_2021_plate2

## Combining the two lanes for each plate ##
for s in `cat ../info/namelist_2021_plate1` ; do cat ./2021_plate1_lane1/${s}.fq.gz ./2021_plate1_lane2/${s}.fq.gz >> ./2021_plate1_combined/$s.fq.gz ; done

for s in `cat ../info/namelist_2021_plate2` ; do cat ./2021_plate2_lane1/${s}.fq.gz ./2021_plate2_lane2/${s}.fq.gz >> ./2021_plate2_combined/$s.fq.gz ; done

for s in `cat ../info/namelist_2017` ; do cat ./2017_lane1/${s}.fq.gz ./2017_lane2/${s}.fq.gz >> ./2017_combined/$s.fq.gz ; done

# Create a new directory for all samples and copy combined samples from all plates there

# The sequencing company's (Floragenex) control sample (FGXCONTROL.fq.gz) should be excluded before proceeding further to reference alignment.


### Reference alignment ###

# The reference genome for Acrocephalus scirpaceus (bAcrSci1) used in this study was published in Sætre et al. 2021 and is available on the European Nucleotide Archive (BioProject PRJEB45715). 

# Unzipping the reference genome
gunzip -c bAcrSci1_1.20210512.curated_primary.fa.gz > bAcrSci1_1.20210512.curated_primary.fasta

# Indexing the reference genome
module load BWA
bwa index ../genome/bAcrSci1_1.20210512.curated_primary.fasta

# Creating a list of all sample names
# Run code in the folder containing all samples from all plates

ls | sed -n 's/\.fq.gz$//p' > ../../info/namelist_2021+2017

# BWA-MEM alignment to reference genome

# Make a namelist
name=$(sed -n ${SLURM_ARRAY_TASK_ID}p ../info/namelist_2021+2017)

# Alignment
module load BWA

bwa mem -M ../genome/bAcrSci1_1.20210512.curated_primary.fasta \
../cleaned/all_samples_combined/${name}.fq.gz | samtools sort -o ../alignments/samples/${name}.bam
