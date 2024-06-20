/******************************************************************************

 EXAMPLE:     keypoint_matching.sas
 DATA:        cv_example_data.zip
              Example image data can be downloaded from:
              https://support.sas.com/documentation/prod-p/vdmml/zip/index.html
 DESCRIPTION: This data set contains color images of varying sizes and type.
 PURPOSE:     This example shows how to crop an image and then save the cropped 
              image. The saved crop is then used as a query image to search for
              matches within the image data set. The matching is done using 
              keypoint/descriptor matching.

              The procedures used in this example are:
              PROC LOADIMAGES
              PROC DISPLAYIMAGES
              PROC PROCESSIMAGES
              PROC SAVEIMAGES
              PROC MATCHIMAGES

 ******************************************************************************/

 title 'Search for a subimage within a set of images using keypoint and descriptor matching.';

/******************************************************************************
 Download the example data.
 ******************************************************************************/
filename exData "&WORKSPACE_PATH./sas/computer_vision/cv_example_data.zip";

proc http url="https://support.sas.com/documentation/prod-p/vdmml/zip/cv_example_data.zip"
out=exData;
run;


/******************************************************************************
 Set up the environment for loading images. Working with images requires a 
 SAS 9 (path based) libref for loading the images as well as a SASVIYA libref
 for processing them.
 ******************************************************************************/

libname mypthlib "&WORKSPACE_PATH.";
libname mylib sasviya;


/******************************************************************************
 Load the images with PROC LOADIMAGES.
 ******************************************************************************/

proc loadimages libref=mypthlib path='sas/computer_vision/cv_example_data.zip';
    output out=mylib.images;
run; 


/******************************************************************************
 Create the subimage that we will use as a query image to search the
 rest of the data set for matches and then save it for use later.
 ******************************************************************************/

proc processimages data=mylib.images(where=(_path_ LIKE '%sas_c_pi.png%'));
    crop x=620 y=355 width=255 height=175;
    output out=mylib.query_image;
run;

title 'Query Image';
proc displayimages data=mylib.query_image;
run;


proc saveimages libref=mypthlib 
                data=mylib.query_image 
                path="sas/computer_vision/matching" 
                prefix="template_" 
                replace; 
run;


/**************************************************************************************************
* Create a mutated version of the original images to demonstrate that our matching algorithm 
* is invarient to rotations, color changes, translations, etc.
**************************************************************************************************/
proc processimages data=mylib.images;
    resize width=1129 height=750;
    crop x=400 y=100 width=600 height=600;
    pad method=replicate top=100;
    pad method=reflect left=225 right=125 bottom=100;
    mutation type=rotate_left angle=30;
    mutation type=darken gamma=0.25;
    output out=mylib.mutated_images;
run;

/**************************************************************************************************
* Attempt to match the template we generated earlier to each of the mutated images in the dataset.
**************************************************************************************************/
proc matchimages data=mylib.mutated_images;
    queryimage libref=mypthlib path='sas/computer_vision/matching/template_sas_c_pi.png';
    method descriptor(type=brisk thresholdratio=0.6);
    output out=mylib.matches highlight;
run;

title 'Match Results';
proc displayimages data=mylib.matches;
run;
