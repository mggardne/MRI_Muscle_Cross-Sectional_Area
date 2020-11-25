# MRI_Muscle_Cross-Sectional_Area
Matlab program for calculating muscle cross-sectional areas for MRI 3T T1-FFE images.

The M-file reads a T1 FFE image file, crops the image, and thresholds the image.  The user then selects a pixel within the subcutaneous fat, femur and muscle in the left and right thighs.  The program separately finds all connected muscle and subcutaneous fat tissues.  The femur is filled and used to exclude the femur and marrow from the noncontractile elements within the muscles.

The program prompts the user to create a polygon region of interest around the flexor muscles.  Since the subcutaneous fat is thicker around the flexors, it is easier to digitize around the flexors.  This is used to divide the muscles into extensor and flexor muscles.  A plot of just the muscles is used to verify the division of the muscle into extensors and flexors before continuing with the program.

The cross-sectional areas for the muscles, subcutaneous fat and noncontractile elements are displayed in the command window.

Plots of the raw image, threshold histogram, muscles (extensors, flexors and total), subcutaneous fat and noncontractile elements are written to the Postscript file, mthresh_*.ps, where "*" is the image name.

See Polygon_ROI_Guide.pdf for tips on creating the polygon ROI.  See musc_thresh.pdf for a guide to using the program.

See comments in musc_thresh.m for more information.
