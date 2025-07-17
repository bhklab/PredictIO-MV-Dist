
val_data <- 'Validation/testDataHartwig.rda'

load(val_data)
load('Validation/Scores/testDataHartwig_sig_score.rda')


#### Create subset for Hartwig Lung & Bladder
HartwigClin <- data.frame(colData(dat$testData))
Hartwig_lung <- HartwigClin[!is.na(HartwigClin$response) & HartwigClin$cancer_type == "Lung", ]
Hartwig_bladder <- HartwigClin[!is.na(HartwigClin$response) & HartwigClin$cancer_type == "Bladder", ]


signature <- dat$signatureData$signature
signature_info <- dat$signatureData$sig.info
predictIOSig <- dat$PredictIOSig



patient_lung <- rownames(Hartwig_lung)
patient_bladder <- rownames(Hartwig_bladder)

#  filter signature score for Hartwig lung and bladder subsets
testExpr <- testExpr[patient_lung, ]
testExpr <- testExpr[patient_bladder, ]

save(testExpr, file = "Validation/Scores/Additionalscore/testDataHartwig_Lung_sig_score.rda")
save(testExpr, file = "Validation/Scores/Additionalscore/testDataHartwig_Bladder_sig_score.rda")


bladder_dat <- dat$testData[, patient_bladder]
signatureData <- list(
      signature = signature,
      sig.info = signature_info
    )
dat <- list(
      testData = bladder_dat,
      signatureData = signatureData,
      PredictIOSig = predictIOSig
    )

new_filename <- file.path("Validation/Additional_othertype", paste0("testData_", "Hartwig_Bladder", ".rda"))
save(dat, file = new_filename)


###############
additional_melanoma <- "Validation_Melanoma/melanoma_testdata"
melanoma_dt <- list.files(additional_melanoma, pattern = "^ICB.*.rda", full.names = TRUE)

additional_other <- "Validation/Additional"
other_dt <- list.files(additional_other, pattern = "^ICB.*.rda", full.names = TRUE)
load(other_dt)

for (file in other_dt) {
  # Load the file (assumes it contains 'dat_icb')
  load(file)
  
  # Check if dat_icb exists in the loaded environment
  if (exists("dat_icb")) {
    testData <- dat_icb
    
    # Create signatureData list
    signatureData <- list(
      signature = signature,
      sig.info = signature_info
    )
    
    # Create the top-level list dat
    dat <- list(
      testData = testData,
      signatureData = signatureData,
      PredictIOSig = predictIOSig
    )
    
    # Define new filename
    new_filename <- file.path(additional_other, paste0("testData_", basename(file)))
    
    # Save the dat list into the new .rda file
    save(dat, file = new_filename)
  } else {
    warning(paste("No 'dat_icb' object found in", file))
  }
}




