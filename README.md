# Register brain atlases to a common time

Sample output:

![37, 40 and 44 weeks][brains]

[brains]: sample.png

The three mono slices are at 37, 40 and 44 weeks, all aligned to the 40
week scan. The colour image is the three slices overlaid, so more colour
means more difference.

The atlases are held on

    /vol/dhcp-derived-data/volumetric-atlases/groupwise/output/dhcp-n275-t36_44-adaptive-sigma_1.00-nmi/atlas

# Remaining issues

Some issues still need to be addressed:

* we don't resample the `scaled` brains, since the scale there is different
  and our dofs won't work

* `transform-image` seems to change the image brightness, very strange ...
  perhaps a problem with the `Fast cubic BSpline` interpolator we are using

* the label images look OK, but the interpolator is obviously not correct for
  this image type ... we should use an interpolator that collects votes over a 
  stencil

# Atlas structure

```
labels
    structures
        brain volumes segmented and labelled with functional regions
    tissues
        brain volumes segmented by white matter, grey matter, CSF, etc.
scaled
    t1w
        T1 images
    t2w
        T2 images
templates
    t1w
        T1 images ... looks a big bigger and sharper than "scaled/t1w"
    t2w
        T2 images ... looks a big bigger and sharper than "scaled/t2w"
```

# Register

Attempt registration with MIRTK, writing the transform to
`t36-37.dof`. Register `templates/t2w`, since they look the best
visually. This will make a transform which will warp t36 to match t37.

```
$ mirtk register -image t37.00.nii.gz -image t36.00.nii.gz -dofout t36-t37.dof
```

Takes about 3m20 to generate fixed, affine and free-form transforms.

# Apply transform

Apply a computed transform with:

```
$ mirtk transform-image t36.00.nii.gz x.nii.gz -dofin t36-t37.dof -interp "Fast cubic BSpline"
```

Pretty quick, ~7s typically. Add 10s if you want to invert the transform. 

# Register all brains

Scans all the t2 templates and generates a det of dofs:

```
$ ./find-dofs.sh
```

# Move all brains to t40

This will do all the brains with the transforms we found from the t2
templates. It doesn't transform the scales volumes since the size is
different and the found dofs will not work. 

```
$ ./apply-dofs.sh 
```

