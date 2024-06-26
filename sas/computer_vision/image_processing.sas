/******************************************************************************

 EXAMPLE:     image_processing.sas
 DATA:        cv_example_data.zip
              Example image data can be downloaded from:
              https://support.sas.com/documentation/prod-p/vdmml/zip/index.html
 DESCRIPTION: This data set contains color images of varying sizes and type.
 PURPOSE:     This example shows how to load images, apply various image processing
              algorithms to the images, and then display them. In addition, this example
              shows how to move the images between image tables and 'flat' tables which
              enable you to use DATA step's to manipulate the image data.

              The procedures used in this example are:
              PROC LOADIMAGES
              PROC DISPLAYIMAGES
              PROC PROCESSIMAGES
              PROC FLATTENIMAGES
              PROC CONDENSEIMAGES
              DATA step

 ******************************************************************************/

 title 'Load and process images using the computer vision procedures and DATA step.';

/******************************************************************************
 Download the example data.
 ******************************************************************************/
filename exData "&WORKSPACE_PATH./sas-viya-workbench-examples/sas/computer_vision/cv_example_data.zip";

proc http url="https://support.sas.com/documentation/prod-p/vdmml/zip/cv_example_data.zip"
out=exData;
run;


/******************************************************************************
 Set up the environmenet for loading images. Working with images requires a 
 SAS 9 (path based) libref for loading the images as well as a SASVIYA libref
 for processing them.
 ******************************************************************************/

libname mypthlib "&WORKSPACE_PATH./sas-viya-workbench-examples";
libname mylib sasviya;


/******************************************************************************
Load the images with PROC LOADIMAGES.
 ******************************************************************************/

proc loadimages libref=mypthlib path='sas/computer_vision/cv_example_data.zip';
    output out=mylib.images;
run; 


/******************************************************************************
 Add salt and pepper noise to the images. 
 ******************************************************************************/

/******************************************************************************
 Resize all of the images (which are of varying sizes) to the same size using
 the PROCESSIMAGES procedure and then display them using PROC DISPLAYIMAGES.
 To make use of wide tables via PROC FLATTENIMAGES and PROC CONDENSEIMAGES all
 images in the table must be the same shape.
 ******************************************************************************/

%let width = 256;
%let height = 256;
proc processimages data=mylib.images;
    resize type=letterbox width=&width height=&height;
    output out=mylib.resized_images;
run;

title 'Resized Images';
proc displayimages data=mylib.resized_images;
run;


/******************************************************************************
 Flatten the images with PROC FLATTENIMAGES, which will put each pixel in to a
 separate column and allow us to use a DATA step to manipulate the pixels. By 
 default the pixels are in BGR order. We use the DATA step to set random pixels 
 to black or white, and then finally convert the flattened table back to an
 image table using PROC CONDENSEIMAGES.
 ******************************************************************************/

proc flattenimages data=mylib.resized_images width=&width height=&height numchannels=COLOR;
    output out=mylib.flat_images;
run; 


data mylib.flat_images_with_sp_noise;
    set mylib.flat_images;
    array cols {*} _numeric_;
    do i = 1 to dim(cols) by 3;
        random = rand("Uniform");
        /* Flattened pixels are BGR order so we iterate by 3's and set each set of 3 
        pixels to 0 or 255 for black or white.*/
        do n = 0 to 2;
            if random > 0.95 then cols{i + n} = 255.0;
            else if random < 0.05 then cols{i + n} = 0.0;
        end;
    end;
    drop i;
run;

proc condenseimages data=mylib.flat_images_with_sp_noise width=&width height=&height 
    numchannels=COLOR;
    output out=mylib.images_width_sp_noise;
run; 

title 'Images with Salt and Pepper Noise';
proc displayimages data=mylib.images_width_sp_noise;
run;


/******************************************************************************
 Use PROC PROCESSIMAGES again to clean up the salt and pepper noise using a 
 median filter. Then display the cleaned results with PROC DISPLAYIMAGES.
 ******************************************************************************/

proc processimages data=mylib.images_width_sp_noise;
    medianfilter kernelsize=3;
    output out=mylib.denoised_images;
run;

title 'Images with Salt and Pepper Noise Removed';
proc displayimages data=mylib.denoised_images;
run;
