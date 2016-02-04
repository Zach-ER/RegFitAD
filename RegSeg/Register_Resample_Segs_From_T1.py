import os
import shutil
import Diff_Preprocess_Defs as DPD

#This registers the synthetic signal to the real one and adjusts the segmentations. 

#topDir = '/Users/zer/RegFitAD/data/Ep/Testing_RegSeg'
topDir = '/Users/zer/RegFitAD/data/Ep/TestT1'
T1Dir = '/Users/zer/RegFitAD/data/Ep/T1'
RAWdir = os.path.join(topDir,'Raw')
refIm = os.path.join(RAWdir,'DT_MD.nii.gz')
rMask = os.path.join(RAWdir,'Brain_mask.nii.gz')
dirBase = 'WholeROI_'

for i in range(50):
	#NAMING 
	itDir = os.path.join(topDir,dirBase +str(i))
	nextDir = os.path.join(topDir,dirBase +str(i+1))
	prevDir = os.path.join(topDir,dirBase +str(i-1))

	floIm = os.path.join(itDir,'T1MD.nii.gz')
	resIm = os.path.join(itDir,'MDregged.nii.gz')
	affIn = os.path.join(topDir,'aff.txt')
	cppName = os.path.join(itDir,'trans.cpp.nii')
	segResName = os.path.join(nextDir,'Segs_Diffspace.nii.gz')

	if os.path.isdir(itDir) and not os.path.isdir(nextDir) and os.path.isfile(floIm):
		os.mkdir(nextDir)

	if not os.path.isfile(resIm) and os.path.isfile(floIm):
		other_args = '-rmask ' + rMask
		DPD.NR_reg(refIm,floIm,cppName,resIm,dbg=False,other_args = other_args)

	T1segName = os.path.join(T1Dir,'Segmentation.nii.gz')
	if not os.path.isfile(segResName) and os.path.isfile(cppName):
		DPD.reg_resample(refIm,T1segName,segResName,cpp = cppName,dbg = False,other_args = '-inter 4 -psf')

	oldName = os.path.join(itDir,'reg_results.txt')
	newName = os.path.join(nextDir,'init_params.txt')
	if not os.path.isfile(newName) and os.path.isfile(oldName):
		shutil.copyfile(oldName,newName)


