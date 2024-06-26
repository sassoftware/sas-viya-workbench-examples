/******************************************************************************

 EXAMPLE:     dataset_augmentation.sas
 DATA:        cv_example_data.zip
              Example image data can be downloaded from:
              https://support.sas.com/documentation/prod-p/vdmml/zip/index.html
 DESCRIPTION: This data set contains color images of varying sizes and type.
 PURPOSE:     This example shows how to use common image augmentation techniques
              to create a dataset fit for training machine learning models.

              The procedures used in this example are:
              PROC LOADIMAGES
              PROC DISPLAYIMAGES
              PROC PROCESSIMAGES
              PROC SAVEIMAGES

 ******************************************************************************/

title 'Augmentating an image data set.';

/******************************************************************************
 Download the example data.
 ******************************************************************************/
filename exData "&WORKSPACE_PATH./sas-viya-workbench-examples/sas/computer_vision/cv_example_data.zip";

proc http url="https://support.sas.com/documentation/prod-p/vdmml/zip/cv_example_data.zip"
out=exData;
run;


/******************************************************************************
 Set up the environment for loading images. Working with images requires a 
 SAS 9 (path based) libref for loading the images as well as a SASVIYA libref
 for processing them.
 ******************************************************************************/

libname mypthlib "&WORKSPACE_PATH./sas-viya-workbench-examples";
libname mylib sasviya;


/******************************************************************************
 Create a fake train/test set by loading the data set and then writing the 
 train images to a subdirectory 'augmentation/train' and test images to a 
 subdirectory 'augmentation/test'.
 ******************************************************************************/

proc loadimages libref=mypthlib path='sas/computer_vision/cv_example_data.zip';
    output out=mylib.images;
run; 

data _null;
    newdir=dcreate('augmentation',"&WORKSPACE_PATH./sas-viya-workbench-examples/sas/computer_vision");
run;

proc saveimages libref=mypthlib 
                data=mylib.images(where=(_id_ < 9))
                path="sas/computer_vision/augmentation/train" 
                replace; 
run;

proc saveimages libref=mypthlib 
                data=mylib.images(where=(_id_ >= 9))
                path="sas/computer_vision/augmentation/test" 
                replace; 
run;


/******************************************************************************
 Load the train/test images with PROC LOADIMAGES. Use recurse to read all 
 images in the directory tree and labellevels=-1 to store the directory 1 level
 up from the image as a label (which will be either 'train' or 'test').
 ******************************************************************************/

proc loadimages libref=mypthlib path='sas/computer_vision/augmentation/' recurse;
    output out=mylib.images labellevels=-1;
run; 

title 'Generated image labels based on directory structure';
proc print data=mylib.images;
    var _id_ _path_ _label_;
run;


/******************************************************************************
 Before augmentation, resize all of the images to the size of the model, in 
 example we choose this 416x416.
 ******************************************************************************/

proc processimages data=mylib.images(where=(_label_ = "train"));
    resize height=416 width=416;
    output out=mylib.resized_images(replace=yes);
run;


/******************************************************************************
-------------------------------------------------------------------------------
 Apply various mutations to the training data to artificially increase the size
 of the dataset - which will increase the robustness of the model training. 
 Everytime we generated a mutated set of images we save them to the train 
 folder with a unique suffix.
-------------------------------------------------------------------------------
 ******************************************************************************/
 
/******************************************************************************
"Zoom in" on the images by cropping the center region and then resizing to the
model size. We can arbitrarily apply as many processing steps as we would LIKE
in any given PROC PROCESSIMAGES statement and they are applied in the order
listed.
 ******************************************************************************/
proc processimages data=mylib.resized_images;
    crop height=350 width=350 x=66 y=66;
    resize height=416 width=416;
    output out=mylib.zoomed_images(replace=yes);
run;

proc saveimages libref=mypthlib 
                data=mylib.zoomed_images 
                path="sas/computer_vision/augmentation/train/" 
                suffix="_zoom"
                replace; 
run;


/******************************************************************************
Blur the images lightly. 
 ******************************************************************************/
proc processimages data=mylib.resized_images;
    gaussianfilter kernelheight=7 kernelwidth=7;
    output out=mylib.blurred_images(replace=yes);
run;

proc saveimages libref=mypthlib 
                data=mylib.blurred_images 
                path="sas/computer_vision/augmentation/train/" 
                suffix="_blur"
                replace; 
run;


/******************************************************************************
Apply color jittering, i.e. randomly adjust the saturation, contrast and 
brightness
 ******************************************************************************/
proc processimages data=mylib.resized_images;
    mutation type=color_jittering;
    output out=mylib.color_jittered_images(replace=yes);
run; 

proc saveimages libref=mypthlib 
                data=mylib.color_jittered_images 
                path="sas/computer_vision/augmentation/train/" 
                suffix="_color_jittered"
                replace; 
run;


/******************************************************************************
Apply color shifting, i.e. randomly shift the intensity of the red, green,
and blue channels.
 ******************************************************************************/
proc processimages data=mylib.resized_images;
    mutation type=color_shifting;
    output out=mylib.color_shifted_images(replace=yes);
run; 

proc saveimages libref=mypthlib 
                data=mylib.color_shifted_images 
                path="sas/computer_vision/augmentation/train/" 
                suffix="_color_shifted"
                replace; 
run;


/******************************************************************************
Apply both lightening via gamma correction and rotation in the clockwise 
direction. 
 ******************************************************************************/
proc processimages data=mylib.resized_images;
    mutation type=rotate_right angle=10 paddingmethod=reflect101;  
    mutation type=lighten gamma=3;  
    output out=mylib.rotated_lightend_images(replace=yes);
run; 

proc saveimages libref=mypthlib 
                data=mylib.rotated_lightend_images 
                path="sas/computer_vision/augmentation/train/" 
                suffix="_rotated_lightend"
                replace; 
run;


/******************************************************************************
Apply both a horizontal flip and sharpen the image.
 ******************************************************************************/
proc processimages data=mylib.resized_images;
    mutation type=horizontal_flip;
    mutation type=sharpen;
    output out=mylib.flipped_sharp_images(replace=yes);
run; 
proc saveimages libref=mypthlib 
                data=mylib.flipped_sharp_images 
                path="sas/computer_vision/augmentation/train/" 
                suffix="_flipped_sharp"
                replace; 
run;


/******************************************************************************
 Finally load the test and augmented training images with PROC LOADIMAGES.
 ******************************************************************************/

proc loadimages libref=mypthlib path='sas/computer_vision/augmentation/' recurse;
    output out=mylib.augmented_images labellevels=-1;
run; 

title 'Augmented train and test images';
proc print data=mylib.augmented_images;
    var _id_ _path_ _label_;
run;
