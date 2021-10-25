# MRI_Muscle_Cross-Sectional_Area
Matlab program for calculating muscle cross-sectional areas for MRI 3T T1-FFE images.

The M-file reads a T1 FFE image file, crops the image, and thresholds the image.  The user then selects a pixel within the subcutaneous fat, femur and muscle in the left and right thighs.  The program separately finds all connected muscle and subcutaneous fat tissues.  The femur is filled and used to exclude the femur and marrow from the noncontractile elements within the muscles.

The program prompts the user to create a polygon region of interest around the flexor muscles.  Since the subcutaneous fat is thicker around the flexors, it is easier to digitize around the flexors.  This is used to divide the muscles into extensor and flexor muscles.  A plot of just the muscles is used to verify the division of the muscle into extensors and flexors before continuing with the program.

The cross-sectional areas for the muscles, subcutaneous fat and noncontractile elements are displayed in the command window.  The program also outputs the results to a spreadsheet, mthreshr.xlsx, in the subdirectory MuscleCSA\ under the MRI_Reliability_Study\ directory.

Plots of the raw image, threshold histogram, muscles (extensors, flexors and total), subcutaneous fat and noncontractile elements are written to a Postscript file mthreshr_??_v?.ps, where ?? is the subject number and ? is the visit number (1 or 2) into the subdirectory MuscleCSA\ under the MRI_Reliability_Study\ directory.  Note that both the results spreadsheet and the plots are all in the same subdirectory.

See Polygon_ROI_Guide.pdf for tips on creating the polygon ROI.  See musc_threshr.pdf for a guide to using the program.

See comments in musc_threshr.m for more information.

Notes on the use of the program:

 1.  This program is for the MRI reliability study.  The Matlab program must start in the MRI_Reliability_Study\ directory.  The directory structure must include subdirectories for each subject and each subject directory must include subdirectories for each visit.  The directory structure is used to identify the MRI images.

 2.  M-file function roi_mov.m must be in the current path or directory.  I recommend putting both musc_threshr.m and roi.mov.m in the MRI_Reliability_Study\ directory.

 3.  The output MS-Excel spreadsheet, mthreshr.xlsx, can NOT be open in another program (e.g. MS-Excel) while using this program.

 4.  Running the program for the same image will result in duplicate data for that image in the spreadsheet.  The spreadsheet should be checked for any duplicate data before any statistical analyzes.
