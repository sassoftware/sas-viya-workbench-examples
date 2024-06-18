/******************************************************************************

 EXAMPLE:     displaying_images.sas
 DATA:        cv_example_data.zip
              Example image data can be downloaded from:
              https://support.sas.com/documentation/prod-p/vdmml/zip/index.html
 DESCRIPTION: This data set contains color images of varying sizes and type.
 PURPOSE:     This example shows how display images and create custom templates
              for displaying metadata along with images.

              The procedures used in this example are:
              PROC DISPLAYIMAGES
              PROC TEMPLATE

 ******************************************************************************/

title 'Displaying images and metadata.';

/******************************************************************************
 Set up the environment for loading images. Working with images requires a 
 SAS 9 (path based) libref for loading the images as well as a SASVIYA libref
 for processing them.
 ******************************************************************************/
libname mypthlib "&WORKSPACE_PATH.";
libname mylib sasviya;


/******************************************************************************
 Load an image dataset with PROC LOADIMAGES. We add optional variables 'width'
 and 'height' as well as use PIXEL encoding, which will store the images in the
 output table as varbinary columns where the image data is raw BGRBGR.. values.
 Using a PIXEL encoding also adds additional metadata to the output table.
 ******************************************************************************/
proc loadimages libref=mypthlib path='sas/computer_vision/cv_example_data.zip';
    output out=mylib.images addvars=(height width) encoding=PIXEL;
run; 

title 'Image metadata added by PROC LOADIMAGES';
proc print data=mylib.images;
    var _height_ _width_ _dimension_ _imageFormat_  _size_ _type_ _id_ _path_;
run;


/******************************************************************************
 Display the images with ODS by using PROC DISPLAYIMAGES.
 ******************************************************************************/
title 'Default image display';
proc displayimages data=mylib.images;
run;


/******************************************************************************
 Create a custom template that combines image metadata. The custom template
 will add the image id above the image, and the height and width below the 
 image. Also, display 4 columns (i.e. 4 images in a row).
 ******************************************************************************/
proc template;
    define DataLayout MyCustomTemplate;
        Region / columns=4;
            Entry "ID=" _id_; 
            Image Image;
            Entry "(height=" _height_ " , width=" _width_ ")"; 
        EndRegion;
    end;
run;


/******************************************************************************
 Use the custom template with PROC DISPLAYIMAGES. Include the VAR statement
 so that the procedure passes those variables to ODS for display. We also
 order by the _id_ and then resize the images to a smaller size because
 our template will display more images per row than the default.
 ******************************************************************************/
proc displayimages data=mylib.images template="MyCustomTemplate";
    var _id_ _height_ _width_;
    orderby _id_;
    resize width=128 height=128;
run;


/******************************************************************************
 Use a macro for dynamic template creation, that is, with the macro create 
 custom templates on the fly and then view the images with PROC DISPLAYIMAGES.
 ******************************************************************************/
%macro disp(dataset, width=256, height=256, nCols=2, nObs=20);
    proc template;
        define DataLayout MyCustomTemplate;
        Region / columns=&nCols;
            Image Image;
        EndRegion;
    end;
    run;

    proc displayimages data=&dataset(obs=&nObs) template="MyCustomTemplate";
        resize width=&width height=&height;
    run;
%mend disp;

%disp(mylib.images, width=512, height=512, nCols=1, nObs=1);
%disp(mylib.images, width=64, height=64, nCols=5, nObs=5);
%disp(mylib.images, width=512, height=512, nCols=1, nObs=3);