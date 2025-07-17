# -----------------------------------------------------------
# Gene Signature Scoring Utility Script
# This script defines a utility function to compute gene signature
# scores for input expression data using various scoring methods.
#
#   - Supports GSVA, ssGSEA, and weighted-mean methods
#   - Takes expression matrix and signature gene sets as input
#   - Returns a matrix of signature scores per sample
# -----------------------------------------------------------
##############################################################
## Load libraries
##############################################################
library(PredictioR)
library(MultiAssayExperiment)
library(reticulate)
library(dplyr)
library(GSVA)

##############################################################
## Define a function to compute gene signature scores
##############################################################
compute_gene_signature_scores <- function(expr, signature, signature_info, study.icb) {

    geneSig.score <- lapply(1:length(signature), function(i){
        print(paste(i , names(signature)[i], sep="/"))
        sig_name <- names(signature)[i]
        
        # check which method is associated with the signature in signature_info and applies the corresponding function.
        if(signature_info[signature_info$signature == sig_name, "method"] == "GSVA"){
            
            geneSig <- geneSigGSVA(dat.icb = expr,
                                sig = signature[[i]],
                                sig.name = sig_name,
                                missing.perc = 0.5,
                                const.int = 0.001,
                                n.cutoff = 15,
                                sig.perc = 0.8,
                                study = study.icb)
            
            
            if(sum(!is.na(geneSig)) > 0){
            geneSig <- geneSig[1,]
            }         
        }
        
        if(signature_info[signature_info$signature == sig_name, "method"] == "Weighted Mean"){
            
            geneSig <- geneSigMean(dat.icb = expr,
                                sig = signature[[i]],
                                sig.name = sig_name,
                                missing.perc = 0.5,
                                const.int = 0.001,
                                n.cutoff = 15,
                                sig.perc = 0.8,
                                study = study.icb)
            
        }
        
        
        if(signature_info[signature_info$signature == sig_name, "method"] == "ssGSEA"){
            
            geneSig <- geneSigssGSEA(dat.icb = expr,
                                    sig = signature[[i]],
                                    sig.name = sig_name,
                                    missing.perc = 0.5,
                                    const.int = 0.001,
                                    n.cutoff = 15,
                                    sig.perc = 0.8,
                                    study = study.icb)
            
            if(sum(!is.na(geneSig)) > 0){
            geneSig <- geneSig[1,]
            }     
            
            
        }
        
        
        if(signature_info[signature_info$signature == sig_name, "method"] == "Specific Algorithm" & sig_name == "COX-IS_Bonavita"){
            
            geneSig <- geneSigCOX_IS(dat.icb = expr,
                                    sig = signature[[i]],
                                    sig.name = sig_name,
                                    missing.perc = 0.5,
                                    const.int = 0.001,
                                    n.cutoff = 15,
                                    sig.perc = 0.8,
                                    study = study.icb)
            
        }
        
        if(signature_info[signature_info$signature == sig_name, "method"] == "Specific Algorithm" & sig_name == "IPS_Charoentong"){
            
            geneSig <- geneSigIPS(dat.icb = expr,
                                sig = signature[[i]],
                                sig.name = sig_name,
                                missing.perc = 0.5,
                                const.int = 0.001,
                                n.cutoff = 15,
                                study = study.icb)
            
        }
        
        if(signature_info[signature_info$signature == sig_name, "method"] == "Specific Algorithm" & sig_name == "PredictIO_Bareche"){
            
            geneSig <- geneSigPredictIO(dat.icb = expr,
                                        sig = signature[[i]],
                                        sig.name = sig_name,
                                        missing.perc = 0.5,
                                        const.int = 0.001,
                                        n.cutoff = 15,
                                        sig.perc = 0.8,
                                        study = study.icb)
            
        }
        
        if(signature_info[signature_info$signature == sig_name, "method"] == "Specific Algorithm" & sig_name == "IPRES_Hugo"){
            
            geneSig <- geneSigIPRES(dat.icb = expr,
                                    sig = signature[[i]],
                                    sig.name = sig_name,
                                    missing.perc = 0.5,
                                    const.int = 0.001,
                                    n.cutoff = 15,
                                    sig.perc = 0.8,
                                    study = study.icb)
            
        }
        
        if(signature_info[signature_info$signature == sig_name, "method"] == "Specific Algorithm" & sig_name == "PassON_Du"){
            
            geneSig <- geneSigPassON(dat.icb = expr,
                                    sig = signature[[i]],
                                    sig.name = sig_name,
                                    missing.perc = 0.5,
                                    const.int = 0.001,
                                    n.cutoff = 15,
                                    sig.perc = 0.8,
                                    study = study.icb)
            
        }
        
        if(signature_info[signature_info$signature == sig_name, "method"] == "Specific Algorithm" & sig_name == "IPSOV_Shen"){
            
            geneSig <- geneSigIPSOV(dat.icb = expr,
                                    sig = signature[[i]],
                                    sig.name = sig_name,
                                    missing.perc = 0.5,
                                    const.int = 0.001,
                                    n.cutoff = 15,
                                    sig.perc = 0.8,
                                    study = study.icb)
        }
        if(sum(!is.na(geneSig)) > 0){
            
            geneSig <- geneSig
            
        }     
        
        if(sum(!is.na(geneSig)) == 0){
            
            geneSig <- rep(NA, ncol(expr))
            
        }
        geneSig
    })

    geneSig.score <- do.call(rbind, geneSig.score)
    rownames(geneSig.score) <- names(signature)

    # bind gene signature scores and remove rows with NA values
    remove <- which(is.na(rowSums(geneSig.score)))
    if(length(remove) > 0){
        geneSig.score <- geneSig.score[-remove, ]}
    
    
    return(geneSig.score)
}
