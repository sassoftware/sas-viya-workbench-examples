# Descriptions of Example SAS Programs <!-- omit in toc -->

- [Programs by PROC](#programs-by-proc)
- [Programs by Data Set](#programs-by-data-set)

## Programs by PROC

Check out the documentation for details on each procedure.

- DATA STEP
  - Bonus ([program](./data_step.sas))
- FOREST
  - Bike Share ([program](./forest_bike.sas))
  - Heart ([program](./classification_heart.sas))
- GLIMMIX
  - Binomial Counts In Randomized Blocks ([notebook](./glimmix_binomial_counts_in_randomized_blocks.sasnb))
- GRADBOOST
  - Students ([program](./gradientboosting_students.sas))
  - Heart ([program](./classification_heart.sas))
- LOGSELECT
  - Banking ([program](./logistic_banking.sas))
  - Simulated ([program](./logistic_simulated.sas))
  - Heart ([program](./classification_heart.sas))
- MCMC
  - Bayesian Autoregressive and Time-Varying Coefficients Time Series Models ([notebook](./mcmc_time_series.sasnb))
- MIXED
  - Random Coefficients ([notebook](./mixed_random_coefficients.sasnb))
  - Repeated Measures ([notebook](./mixed_repeated_measures.sasnb))
- PCA
  - Breast Cancer ([program](./pca_breastcancer.sas))
  - Mushroom ([program](./pca_mushroom.sas))
  - Simulated ([program](./pca_simulated.sas))
- REGSELECT
  - Simulated ([program](./linear_simulated.sas))
  - Bike Share ([program](./linear_bike.sas))
- SVMACHINE
  - Students ([program](./svm_students.sas))
  - Heart ([program](./classification_heart.sas))
- TREESPLIT
  - Adult ([program](./decisiontree_adult.sas))
  - Heart ([program](./classification_heart.sas))

## Programs by Data Set

Check out the data set [descriptions](../data/DATA_DESCRIPTION.md) for details
on each data set.

- Adult
  - TREESPLIT ([program](./decisiontree_adult.sas))
  - Linear & SVM Modeling ([program](./machine_learning/linear_svm_models_class_target.sas))
  - Tree-based Modeling ([program](./machine_learning/tree_models_class_target.sas))
- Banking
  - LOGSELECT ([program](./logistic_banking.sas))
- Bike Share
  - FOREST ([program](./forest_bike.sas))
  - REGSELECT ([program](./linear_bike.sas))
  - Linear & SVM Modeling ([program](./machine_learning/linear_svm_models_interval_target.sas))
  - Tree-based Modeling ([program](./machine_learning/tree_models_interval_target.sas))
- Bonus
  - DATA STEP ([program](./data_step.sas))
- Breast Cancer
  - PCA ([program](./pca_breastcancer.sas))
- Heart
  - Classification ([program](./classification_heart.sas))
- Mushroom
  - PCA ([program](./pca_mushroom.sas))
- Simulated (generated within the script)
  - GLIMMIX ([notebook](./glimmix_binomial_counts_in_randomized_blocks.sasnb))
  - LOGSELECT ([program](./logistic_simulated.sas))
  - MCMC ([notebook](./mcmc_time_series.sasnb))
  - MIXED (Random Coefficients) ([notebook](./mixed_random_coefficients.sasnb))
  - MIXED (Repeated Measures) ([notebook](./mixed_repeated_measures.sasnb))
  - PCA ([program](./pca_simulated.sas))
  - REGSELECT ([program](./linear_simulated.sas))
- Students
  - SVMACHINE ([program](./gradientboosting_students.sas))
