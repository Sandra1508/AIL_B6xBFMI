setwd("C:/Users/User/Desktop/AIL B6xBFMI/candidategenesdata")

myvcf <- read.csv("all_combined.vcf", sep = "\t", skip = 169, header=FALSE, colClasses="character")
dim(myvcf)

colnames(myvcf) <- c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "BFMI860-12", "BFMI861-S1", "BFMI861-S2")

GTs1 <- unlist(lapply(strsplit(myvcf[,"BFMI861-S1"], ":"), "[", 1))
GTs1[which(GTs1 == "./.")] <- NA

interesting <- which(GTs1 != "0/0")
myvcf <- myvcf[interesting,]

complexSNPs <- grep(",", myvcf[,"ALT"])
myvcf <- myvcf[-complexSNPs,]

# Add a vep like 'location' column to the vcf file
myvcf <- cbind(location = as.character(paste0(myvcf[,"CHROM"], ":", myvcf[, "POS"], "-", myvcf[, "POS"])), myvcf)

#Keep only the non-duplicated entries, (remove the duplicated entries)
myvcf <- myvcf[which(!duplicated(myvcf[,"location"])),]

# Load the VEP results
myvep <- read.csv("vep_predictions_6_18_2019.txt", sep = "\t", skip = 1, header=FALSE, colClasses="character")
colnames(myvep) <- c("Uploaded_variation", "Location", "Allele", "Consequence", "IMPACT", "SYMBOL", "Gene", "Feature_type", "Feature", "BIOTYPE", "EXON", "INTRON", "HGVSc", "HGVSp", "cDNA_position", "CDS_position", "Protein_position", "Amino_acids", "Codons", "Existing_variation", "DISTANCE", "STRAND", "FLAGS", "SYMBOL_SOURCE", "HGNC_ID", "TSL", "APPRIS", "REFSEQ_MATCH", "SIFT", "CLIN_SIG", "SOMATIC", "PHENO", "MOTIF_NAME", "MOTIF_POS", "HIGH_INF_POS", "MOTIF_SCORE_CHANGE")

allgenes <- unique(myvep[which(myvep[, "Consequence"] == "missense_variant"),"Location"])
myvcf[which(myvcf[, "location"] %in% allgenes),]

# Keep only the VEP entries that are in the VCF file
myvep <- myvep[which(myvep[, "Location"] %in% myvcf[, "location"]),]

# Do the genes first since we're looking for non-syn SNPs
vepgenes <- myvep[which(myvep[, "SYMBOL"] != "-"),]
allgenes <- unique(vepgenes[, "SYMBOL"])

resM <- matrix(NA, length(allgenes), 4)
resM[,1] <- allgenes
colnames(resM) <- c("name", "chr", "missense variant", "consequence")

mrow <- 1
for (gene in allgenes) {
  snpingene <- vepgenes[which(vepgenes[,"SYMBOL"] == gene),]
  chr <- unique(unlist(lapply(strsplit(snpingene[, "Location"], ":"), "[",1)))
  resM[mrow, "chr"] <- chr
  hasMissense <- any(unique(snpingene[,"Consequence"]) == "missense_variant")
  if(hasMissense) {
    resM[mrow, "missense variant"] <- "+"
    if(length(grep("tolerated(", snpingene[,"SIFT"], fixed=TRUE)) > 0) resM[mrow, "consequence"] <- "-"
    if(length(grep("tolerated_low_confidence(", snpingene[,"SIFT"], fixed=TRUE)) > 0) resM[mrow, "consequence"] <- "0"
    if(length(grep("deleterious_low_confidence(", snpingene[,"SIFT"], fixed=TRUE)) > 0) resM[mrow, "consequence"] <- "+"
    if(length(grep("deleterious(", snpingene[,"SIFT"], fixed=TRUE)) > 0) resM[mrow, "consequence"] <- "++"
  }else{
    resM[mrow, "missense variant"] <- "-"
  }
  mrow <- mrow + 1
  cat(mrow, "/", length(allgenes), "\n")
}
resM[which(resM[,"consequence"] == "++"),]

cat(allgenes, sep="\n", file="listofallgenes.txt")

mgidata <- read.csv("MGIgeneExpressionQuery_2_7_19.txt", sep = "\t", colClasses="character")

table(mgidata[, "Theiler.Stage"])

mgidata = mgidata[which(mgidata[, "Theiler.Stage"] == "28"), ]

mtable = table(mgidata[, "Structure"])
mtable[mtable > 20]


tissues = c("brain", "liver", "pancreas", "skeletal muscle", "hypothalamus")
mgidata = mgidata[which(mgidata[, "Structure"] %in% tissues),]

resM = cbind(resM, "brain" = NA, "liver" = NA, "pancreas" = NA, "skeletal muscle" = NA, "hypothalamus" = NA)
rownames(resM) = resM[,1]

for (tissue in tissues){
	for (gene in allgenes){
		idx = which(mgidata[, "Gene.Symbol"] == gene)
		if(length(idx) == 0){
			resM[gene, tissue] = "?"
		}else{
			if(any(tissue %in% mgidata[idx, "Structure"])){
				resM[gene, tissue] <- "+"
			}else{
				resM[gene, tissue] <- "-"
			}
		}
	}
}

write.table(resM, file = "prioritylist.txt", sep = "\t", quote = FALSE, row.names = FALSE)



#example: samtools view -b -h /halde/BFMI_Alignment_Mar19/merged_sorted_860-S12.bam "3:30000000-40000000" > ~/flo/860-S12_chr3-30-40mb.bam
#example: samtools index  ~/flo/860-S12_chr3-30-40mb.bam



samtools view -b -h /halde/BFMI_Alignment_Mar19/merged_sorted_860-S12.bam "1:15000000-17000000" > ~/mastersprojectanalysis/subsetchromosome1/chr1-15-17mb.bam
samtools index  ~/mastersprojectanalysis/subsetchromosome1/chr1-15-17mb.bam

samtools view -b -h /halde/BFMI_Alignment_Mar19/merged_sorted_860-S12.bam "3:30000000-50000000" > ~/mastersprojectanalysis/subsetchromosome1/chr1-30-50mb.bam
samtools index  ~/mastersprojectanalysis/subsetchromosome1/chr1-30-50mb.bam


samtools view -b -h /halde/BFMI_Alignment_Mar19/merged_sorted_860-S12.bam "5:10000000-30000000" > ~/mastersprojectanalysis/subsetchromosome1/chr1-10-30mb.bam
samtools index  ~/mastersprojectanalysis/subsetchromosome1/chr1-10-30mb.bam


samtools view -b -h /halde/BFMI_Alignment_Mar19/merged_sorted_860-S12.bam "8:8000000-100000000" > ~/mastersprojectanalysis/subsetchromosome1/chr1-8-10mb.bam
samtools index  ~/mastersprojectanalysis/subsetchromosome1/chr1-8-10mb.bam


