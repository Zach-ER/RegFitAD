import os
import shutil
import Diff_Preprocess_Defs as DPD

#to compose two transformations
def reg_compose(trans1,ref1,trans2,ref2,outTrans):
	sysCmd = ' '.join(['reg_transform','-comp',trans1,trans2,outTrans,'-ref',ref1,'-ref2',ref2])
	#os.system(sysCmd)
	print sysCmd

#This registers the synthetic signal to the real one and adjusts the segmentations. 

#topDir = '/Users/zer/RegFitAD/data/Ep/Testing_RegSeg'
topDir = '/Users/zer/RegFitAD/data/Ep/TestT1'
T1Dir = '/Users/zer/RegFitAD/data/Ep/T1'
RAWdir = os.path.join(topDir,'Raw')
refIm = os.path.join(T1Dir,'MD_T1_space.nii.gz')
rMask = os.path.join(T1Dir,'Brain_mask.nii.gz')
dirBase = 'prop_0'

MDdiff = os.path.join(RAWdir,'DT_MD.nii.gz')

aff_from_T1_to_diff = os.path.join(T1Dir,'T1_TO_MD.txt')

for i in range(10):
	#NAMING 
	itDir = os.path.join(topDir,dirBase +str(i))
	nextDir = os.path.join(topDir,dirBase +str(i+1))
	prevDir = os.path.join(topDir,dirBase +str(i-1))

	floIm = os.path.join(itDir,'T1MD.nii.gz')
	resIm = os.path.join(itDir,'T1_MD_Regged.nii.gz')
	affIn = os.path.join(topDir,'aff.txt')
	cppName = os.path.join(itDir,'trans.cpp.nii')
	segResName = os.path.join(nextDir,'Segs_diffspace.nii.gz')
	maskOutName = os.path.join(nextDir,'T1_Brain_mask.nii.gz')

	if os.path.isdir(itDir) and not os.path.isdir(nextDir) and os.path.isfile(floIm):
		os.mkdir(nextDir)

	if not os.path.isfile(resIm) and os.path.isfile(floIm):
		other_args = '-rmask ' + rMask
		DPD.NR_reg(refIm,floIm,cppName,resIm,dbg=False,other_args = other_args)

## This is for when we don't want to keep resampling the matrix 

	T1segName = os.path.join(itDir,'T1_Segmentation.nii.gz')
	T1tmpName = os.path.join(itDir,'T1_Segmentation_Regged.nii.gz')
	T1MaskName = os.path.join(itDir,'T1_Brain_mask.nii.gz')
	MaskTempName = os.path.join(itDir,'T1_Brain_Mask_Regged.nii.gz')

	NextT1SegName = os.path.join(nextDir,'T1_Segmentation.nii.gz')

	if (not os.path.isfile(segResName)) and os.path.isfile(cppName):
		DPD.reg_resample(refIm,T1segName,T1tmpName,cpp = cppName,dbg = False,other_args = '-inter 3')
		DPD.reg_resample(MDdiff,T1tmpName,segResName,cpp = aff_from_T1_to_diff,dbg = False,other_args = '-inter 3 -psf')
		DPD.reg_resample(refIm,T1MaskName,MaskTempName,cpp = cppName,dbg = False,other_args = '-NN')
		DPD.reg_resample(MDdiff,MaskTempName,maskOutName,cpp = aff_from_T1_to_diff,dbg = False,other_args = '-NN')
		shutil.copyfile(T1tmpName,NextT1SegName)

	oldName = os.path.join(itDir,'reg_results.txt')
	newName = os.path.join(nextDir,'init_params.txt')
	if not os.path.isfile(newName) and os.path.isfile(oldName):
		shutil.copyfile(oldName,newName)


