#Run using snakemake -j32 -F
#Run using snakemake -j32 --touch
import os
import os.path

### To manually install the required environment: mamba install -c bioconda -c conda-forge snakemake phyml mafft mrbayes revbayes trimal bioconductor-shortread r-stringr r-data.table r-phyclust seqmagick


## Install prerequisites manually:
## conda create --name Analyser
## conda activate Initiator
## conda install -c bioconda -c conda-forge snakemake phyml mafft mrbayes revbayes trimal bioconductor-shortread r-stringr r-data.table r-phyclust seqmagick
## or
## conda install -c conda-forge mamba
## mamba install -c bioconda -c conda-forge snakemake phyml mafft mrbayes revbayes trimal bioconductor-shortread r-stringr r-data.table r-phyclust seqmagick




##### Load Input Files and usefull info  #####


DATASETS={}
ENDING_EXT={}
DATASETS_FILE=open('Datasets.txt','r')

Labels=DATASETS_FILE.readline()
counter=1
for line in DATASETS_FILE:
    line=line.strip().split()
    Dataset=line[0]
    Dataset=Dataset.split('.')
    Ending=Dataset[len(Dataset)-1]
    Dataset='.'.join(Dataset[:len(Dataset)-1])
    AncSamples=line[1].split(',')
    
    ENDING_EXT[Dataset]=Ending
    
    if Dataset in DATASETS:
        DATASETS[Dataset].append([x for x in AncSamples])

    else:
        DATASETS[Dataset]=[[x for x in AncSamples]]




print(DATASETS)

JOINED_NAMES=[]
GENES_OF_DATASET={}

for DATASET,ANC_SAMPLES in DATASETS.items():
    for SAMPLES in ANC_SAMPLES:
    
        DATASET_NAME=DATASET
        JOINED_NAMES.append(DATASET_NAME)

    ####### Find Genes   
        if isinstance(SAMPLES, list) is True:

            TOTAL_GENES=[]
            
            DUPLICATES_CHECK_LIST=[]
            
            for SAMPLE in SAMPLES:
                REF_FASTA=open('Workspace/1_OG_Dataset/{}.{}'.format(DATASET,ENDING_EXT[DATASET]),'r')
                for line in REF_FASTA:
                    line=line.strip().split('/')[0]
                    line=line.strip().split('_')
                    if len(line)>1:
                        if '_'.join(line[:len(line)-1]) == '>' + SAMPLE:
                            TOTAL_GENES.append(line[len(line)-1])

                            
            TOTAL_GENES=list(set(TOTAL_GENES))
            
            
        if isinstance(SAMPLES, list) is False:
            print(SAMPLES)
            TOTAL_GENES=[]
            
            REF_FASTA=open('Workspace/1_OG_Dataset/{}.{}'.format(DATASET,ENDING_EXT[DATASET]),'r')
            for line in REF_FASTA:
                line=line.strip().split('/')[0]
                line=line.strip().split('_')
                if len(line)>1:
                    if '_'.join(line[:len(line)-1]) == '>' + SAMPLES:
                        TOTAL_GENES.append(line[len(line)-1])
            TOTAL_GENES=list(set(TOTAL_GENES))
            
    GENES_OF_DATASET[DATASET_NAME]=TOTAL_GENES



for DATASET,ANC_SAMPLES in DATASETS.items():
    for SAMPLES in ANC_SAMPLES:

        DATASET_NAME=DATASET

        
        
        
    GENES=GENES_OF_DATASET[DATASET_NAME]
    print(f'Analysing Dataset of file {DATASET}, with {ANC_SAMPLES} assigned as ancient proteomes and containing in total these genes: {GENES}')

SAMPLES=JOINED_NAMES













##############################################################################################################################################################################################################################################################################################################################################
##############################################################################################################################################################################################################################################################################################################################################
##############################################################################################################################################################################################################################################################################################################################################
## Starting Rule




rule all:
    input:
        # expand('Workspace/2_DATASETS/{sample}/Samples.txt',sample=SAMPLES),
        # expand('Workspace/2_DATASETS/{sample}/Alignment_Done',sample=SAMPLES),
        expand('Workspace/2_DATASETS/{sample}/Info_and_Checking_Done',sample=SAMPLES),
        expand('Workspace/2_DATASETS/{sample}/PhyML_Individual_Genes_Done',sample=SAMPLES),
        expand('Workspace/2_DATASETS/{sample}/PhyML_Concatenated_Genes_Done',sample=SAMPLES),
        #expand('Workspace/2_DATASETS/{sample}/MrBayes_Concatenated_Genes_Done',sample=SAMPLES),
        expand('Workspace/2_DATASETS/{sample}/RevBayes_Concatenated_Genes_Done',sample=SAMPLES),
        expand('Workspace/2_DATASETS/{sample}/Collected_Alignments/Alignments_Collected',sample=SAMPLES)































##############################################################################################################################################################################################################################################################################################################################################
## Dataset Pipeline ##





## Organise Datasets
#
rule Organise_Data:
    input:
        "Datasets.txt"
    output:
        expand('Workspace/2_DATASETS/{sample}/Samples.txt',sample=SAMPLES)
    run:
        
        for DATASET,ANC_SAMPLES in DATASETS.items():
            for SAMPLES in ANC_SAMPLES:
                shell("""echo '{}' >  Workspace/2_DATASETS/{}/Samples.txt;""".format('\n'.join(SAMPLES),DATASET)) #append all versions of analysis




## Create a Genes folder for every dataset
#
rule Create_Genes_Folders:
    input:
        "Datasets.txt"
    output:
        expand('Workspace/2_DATASETS/{sample}/Genes.txt',sample=SAMPLES)
    run:

        for DATASET,ANC_SAMPLES in DATASETS.items(): ### Create and fill in the Genes.txt file for each dataset
            
            for SAMPS in ANC_SAMPLES:
                DATASET_NAME=DATASET
            
            GENE_FILE=open('Workspace/2_DATASETS/{}/Genes.txt'.format(DATASET_NAME),'w')
            
            for GENE in GENES_OF_DATASET[DATASET_NAME]:
                GENE_FILE.write(GENE)
                if GENE != GENES_OF_DATASET[DATASET_NAME][len(GENES_OF_DATASET[DATASET_NAME])-1]:
                    GENE_FILE.write('\n')
            GENE_FILE.close()




## For each dataset, split it into gene specific sub-datasets
#
rule Create_Genes_Folders2:
    input:
        'Workspace/2_DATASETS/{sample}/Genes.txt',
        'Workspace/2_DATASETS/{sample}/Samples.txt'
    output:
        'Workspace/2_DATASETS/{sample}/Foldering_Done'
    run:
        ###### shell("""cat Workspace/2_DATASETS/{}/Genes.txt |while read line; do rm -rf $line; mkdir $line; done;""".format(X))
        DATASET=wildcards.sample
        SAMPL_FILE='Workspace/2_DATASETS/{}/Samples.txt'.format(wildcards.sample)
        SAMPLES=[]
        for LINE in SAMPL_FILE:
            LINE=LINE.strip()
            SAMPLES.append(LINE)
        
        print(DATASET,SAMPLES)
        
        ##### Use dataset name as input for the R script
        ENDING=ENDING_EXT[DATASET]
        
        shell("""Rscript Rscripts/Rscript1.r /Workspace/2_DATASETS/{wildcards.sample} Workspace/1_OG_Dataset/{DATASET}.{ENDING};""")
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/Foldering_Done;""")



## Above but for all datasets
#         
rule Create_Genes_Folders2_for_All:
    input:
        expand('Workspace/2_DATASETS/{sample}/Genes.txt',sample=SAMPLES)



## Align each dataset            
#
rule Align_Gene_Dataset:
    input:
        'Workspace/2_DATASETS/{sample}/Foldering_Done'
    output:
        'Workspace/2_DATASETS/{sample}/Alignment_Done'
    threads: 32
    run:
        GENES_CAT=open('Workspace/2_DATASETS/{}/Genes.txt'.format(wildcards.sample),'r')
        for GENE_CAT in GENES_CAT:
            GENE_CAT=GENE_CAT.strip()
            shell("""mafft --ep 0 --op 0.5 --lop -0.5 --genafpair --maxiterate 20000 --thread {threads} --bl 80 --fmodel Workspace/2_DATASETS/{wildcards.sample}/{GENE_CAT}/{GENE_CAT}_no_ancient.fa >  Workspace/2_DATASETS/{wildcards.sample}/{GENE_CAT}/{GENE_CAT}_no_ancient_aln.fa;""")
            shell("""mafft-einsi  --addlong Workspace/2_DATASETS/{wildcards.sample}/{GENE_CAT}/{GENE_CAT}_ancient.fa Workspace/2_DATASETS/{wildcards.sample}/{GENE_CAT}/{GENE_CAT}_no_ancient_aln.fa  > Workspace/2_DATASETS/{wildcards.sample}/{GENE_CAT}/{GENE_CAT}_re_aln.fa;""")
            shell("""trimal -in Workspace/2_DATASETS/{wildcards.sample}/{GENE_CAT}/{GENE_CAT}_re_aln.fa -out Workspace/2_DATASETS/{wildcards.sample}/{GENE_CAT}/{GENE_CAT}_aln.fa  -noallgaps;""")
        GENES_CAT.close()
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/Alignment_Done;""")




## Align ALL datasets       
#
rule Align_All_Gene_Datasets:
    input:
        expand('Workspace/2_DATASETS/{sample}/Foldering_Done',sample=SAMPLES)          
            

 
############
            ##### Other ideas - not implemented
            #### ADD Ancient sequence to alignment##   mafft --ep 0 --genafpair --maxiterate 1000 --addprofile COL17A1_ancient.fa COL17A1_aln.fa > COL17A1_NEW.fa
            #### ADD Ancient sequence to alignment##   mafft-einsi --seed COL17A1_aln.fa  COL17A1_ancient.fa > COL17A1_NEW.fa
            #### shell("""cat Workspace/2_DATASETS/{}/Genes.txt | while read line; do clustalw -INFILE=Workspace/2_DATASETS/{}/$line/$line"_o.fa" -outfile=Workspace/2_DATASETS/{}/$line/$line"_aln.fa" -PWMATRIX=BLOSUM -PWGAPOPEN=10 -ITERATION=TREE -NUMITER=1000 -OUTORDER==INPUT -OUTPUT=FASTA; done;""".format(X,X,X))
            #### shell("""cat Workspace/2_DATASETS/{}/Genes.txt | while read line; do clustalw -PROFILE1=Workspace/2_DATASETS/{}/$line/$line"_no_ancient_aln.fa" -PROFILE2=Workspace/2_DATASETS/{}/$line/$line"_ancient.fa" -outfile=Workspace/2_DATASETS/{}/$line/$line"_re_aln.fa" -NUMITER=1000 -PWMATRIX=BLOSUM -PWGAPEXT=0.01 -OUTORDER==INPUT -OUTPUT=FASTA; done;""".format(X,X,X,X))
############





## Generate statistics for each sample in each dataset, swap L/M aminoacids based on reference samples           
#            
rule Generate_Stats_and_Check_LM_AminoAcids:
    input:
        'Workspace/2_DATASETS/{sample}/Alignment_Done'
    output:
        'Workspace/2_DATASETS/{sample}/Info_and_Checking_Done'
    run:       
        shell("""Rscript Rscripts/Rscript2.r /Workspace/2_DATASETS/{wildcards.sample} ;""")
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/Info_and_Checking_Done ;""")

## Request above for all datasets          
# 
rule Generate_Stats_and_Check_LM_AminoAcids_for_All:
    input:
        expand('Workspace/2_DATASETS/{sample}/Alignment_Done',sample=SAMPLES)





























##############################################################################################################################################################################################################################################################################################################################################
## If Alignment is good, now move on to concatenation, formating and data prepareation ##




## Concatenate Genes of Dataset into one new fasta           
#
rule Generate_Concatenated_Datasets:
    input:
        'Workspace/2_DATASETS/{sample}/Info_and_Checking_Done'
    output:
        'Workspace/2_DATASETS/{sample}/Concatenation_Done'
    params:
        Protein_Cutoff=0.01
    run:        
        shell("""Rscript Rscripts/Rscript3.r /Workspace/2_DATASETS/{wildcards.sample} {params.Protein_Cutoff} ;""")
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/Concatenation_Done ;""")


## Request Concatenation for all datasets           
#
rule Generate_Concatenated_Datasets_for_All:
    input:
        expand('Workspace/2_DATASETS/{sample}/Info_and_Checking_Done',sample=SAMPLES)





## Convert FASTA files to Phylip format        
#
rule Generate_Phylip_Format:
    input:
        'Workspace/2_DATASETS/{sample}/Concatenation_Done'
    output:
        'Workspace/2_DATASETS/{sample}/Phylip_Format_Done'
    run:        
        shell("""Rscript Rscripts/Rscript4.r /Workspace/2_DATASETS/{wildcards.sample};""")
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/Phylip_Format_Done;""")


## Request Conversion to Phylip for all Datasets       
#
rule Generate_Phylip_Format_for_All:
    input:
        expand('Workspace/2_DATASETS/{sample}/Concatenation_Done',sample=SAMPLES)





## Run PhyML for each individual protein and generate trees      
#
rule Run_PhyML_for_Individual_Gene:
    input:
        'Workspace/2_DATASETS/{sample}/Phylip_Format_Done'
    output:
        'Workspace/2_DATASETS/{sample}/PhyML_Individual_Genes_Done'
    threads: 25
    run:
        GENES=GENES_OF_DATASET[wildcards.sample]
        for GENE in GENES:
            shell("""
            cd Workspace/2_DATASETS/{wildcards.sample}/{GENE}/;\
            RAND=$(( $RANDOM %99999));\
            mpirun -n {threads} --oversubscribe phyml-mpi -i {GENE}_aln_e.phy -d aa -b 100 -m JTT -c 4 -a e -s BEST -v e -o tlr -f m --rand_start --n_rand_starts 3 --r_seed $RAND --print_site_lnl --print_trace --no_memory_check < /dev/null;
            """)
            shell("""touch Workspace/2_DATASETS/{wildcards.sample}/PhyML_Individual_Genes_Done;""")


## Request PhyML output for All datasets and all genes
#
rule Run_PhyML_for_All_Datasets_All_Individual_Genes:
    input:
        expand('Workspace/2_DATASETS/{sample}/Phylip_Format_Done',sample=SAMPLES)   


       
## Run PhyML on the concatenated datasets
#        
rule Run_PhyML_Concatenated_Genes:
    input:
        'Workspace/2_DATASETS/{sample}/Concatenation_Done',
        'Workspace/2_DATASETS/{sample}/Phylip_Format_Done'
    output:
        'Workspace/2_DATASETS/{sample}/PhyML_Concatenated_Genes_Done'
    threads: 25
    run:
        shell( """
        cd  Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/;\
        RAND=$(( $RANDOM %999));\
        mpirun -n {threads} --oversubscribe phyml-mpi -i CONCATINATED_aln_e.phy -d aa -b 100 -m JTT -a e -s BEST -v e -o tlr -f m --rand_start --n_rand_starts 4 --r_seed $RAND --print_site_lnl --print_trace --no_memory_check < /dev/null;""")
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/PhyML_Concatenated_Genes_Done;""")

## Run PhyML on the concatenated datasets
#      
rule Run_All_PhyML_Concatenated_Genes:
    input:
        expand('Workspace/2_DATASETS/{sample}/Concatenation_Done',sample=SAMPLES),
        expand('Workspace/2_DATASETS/{sample}/Phylip_Format_Done',sample=SAMPLES)

##
# Transform from fasta to Nexus format for MrBayes
rule Generate_NEXUS_format:
    input:
        'Workspace/2_DATASETS/{sample}/Concatenation_Done'
    output:
        'Workspace/2_DATASETS/{sample}/NEXUS_Concatenated_Genes_Done'
    run:        
        # shell( """
        # seqmagick convert --output-format nexus --alphabet protein Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o.fa Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o.nex;
        # """)### Turn into nexus file
        # shell("""sed -i "s/[']//g" Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o.nex; """) #### Fix 'Sample' that is automatically genereated for some labels
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/NEXUS_Concatenated_Genes_Done;""")



## 
# Do a MrBayes run on the concatenated dataset
rule Run_MrBayes_Concatenated_Genes:
    input:
        'Workspace/2_DATASETS/{sample}/NEXUS_Concatenated_Genes_Done'
    output:
        'Workspace/2_DATASETS/{sample}/MrBayes_Concatenated_Genes_Done'
    threads: 32

    run:
        # DIV=max(int(threads/4),2)
        # DIV_2=max(int(DIV/2),2)

        # shell("""RAND=$(( $RANDOM %999));\
        # rm -rf Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o.nex.*;\
        # echo -e 'set autoclose=yes\nexecute Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o.nex'>Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/MrBatch.txt;\
        # cat Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/Partition_Helper >> Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/MrBatch.txt;\
        # echo -e 'prset aamodelpr = mixed;\nmcmc nchains = {DIV} nruns={DIV_2} ngen = 5000000 samplefreq=100 printfreq=100 diagnfreq=1000;\nsumt relburnin = yes burninfrac = 0.25;\nsump;\nquit;'>>Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/MrBatch.txt;\
        # mpirun -np {DIV} mb-mpi < Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/MrBatch.txt > Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/log_MB.txt;\
        # echo "MrBayes Run Done";\
        # """)
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/MrBayes_Concatenated_Genes_Done; """)
        #### To unlink partitions # unlink statefreq=(all) revmat=(all) shape=(all) pinvar=(all);\n
        ###### \nstoprule=yes; \nmcmcp stopval=0.01;





rule Generate_RevBayes_NEXUS_format:
    input:
        'Workspace/2_DATASETS/{sample}/NEXUS_Concatenated_Genes_Done'
    output:
        'Workspace/2_DATASETS/{sample}/NEXUS_RB_Concatenated_Genes_Done'
    # threads:1
    
    run:
        # shell("""cp Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o.nex Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o_Rev.nex""")
        # shell("""cat Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/Partition_Helper_RB >> Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o_Rev.nex""")
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/NEXUS_RB_Concatenated_Genes_Done; """)


## 
# Do a RevBayes run on the concatenated dataset
rule Run_RevBayes_Concatenated_Genes:
    input:
        'Workspace/2_DATASETS/{sample}/NEXUS_RB_Concatenated_Genes_Done'
    output:
        'Workspace/2_DATASETS/{sample}/RevBayes_Concatenated_Genes_Done'
    # threads: 16

    run:


        # shell("""RAND=$(( $RANDOM %999));\
        # rm -rf Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/output_RevBayes;\
        
        # cp Rscripts/RevScript.rb Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/RevScript.rb;\
        
        # cp Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o.nex Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o_Rev.nex;\
        
        # cat Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/Partition_Helper_RB >> Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o_Rev.nex ;\
        
        # cd Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/
        
        # mpirun -np {threads} --oversubscribe  rb-mpi  RevScript.rb > log_RB.txt;\
        
        # echo "RevBayes Run Done";\
        # """)
        shell("""touch Workspace/2_DATASETS/{wildcards.sample}/RevBayes_Concatenated_Genes_Done; """)

        ### Old commands
        ###echo -e 'data <- readDiscreteCharacterData("Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/CONCATINATED_o_Rev.nex")' > Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/RevScript.rb;\
        ###cat Rscripts/RevScript.rb >> Workspace/2_DATASETS/{wildcards.sample}/CONCATINATED/RevScript.rb;\



## 
# Collect Alignments into one folder
rule Gether_Alignments_In_One_Place:
    input:
        'Workspace/2_DATASETS/{sample}/Concatenation_Done',
        'Workspace/2_DATASETS/{sample}/Alignment_Done'
        
        
    output:
        'Workspace/2_DATASETS/{sample}/Collected_Alignments/Alignments_Collected'
    run:
        # COLLECTION_FOLDER=F'Workspace/2_DATASETS/{wildcards.sample}/Collected_Alignments'
        # if os.path.exists(COLLECTION_FOLDER)==False:
        #     os.mkdir(COLLECTION_FOLDER)


        # GENES=GENES_OF_DATASET[wildcards.sample]
        # for GENE in GENES:
        #     shell("cp Workspace/2_DATASETS/{wildcards.sample}/{GENE}/{GENE}_aln_e.fa Workspace/2_DATASETS/{wildcards.sample}/Collected_Alignments/{GENE}_final_alignment.fa;")
        shell("touch Workspace/2_DATASETS/{wildcards.sample}/Collected_Alignments/Alignments_Collected")