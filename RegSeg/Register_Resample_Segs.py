import os
import shutil
import Diff_Preprocess_Defs as DPD

#This registers the synthetic signal to the real one and adjusts the segmentations. 

topDir = '/Users/zer/RegFitAD/data/Ep/Testing_RegSeg'
RAWdir = os.path.join(topDir,'Raw')
refIm = os.path.join(RAWdir,'DW.nii.gz')
rMask = os.path.join(RAWdir,'Brain_mask.nii.gz')

for i in range(10):
	print i
	itDir = os.path.join(topDir,'it_0'+str(i))
	nextDir = os.path.join(topDir,'it_0'+str(i+1))
	if os.path.isdir(itDir) and not os.path.isdir(nextDir):
		os.mkdir(nextDir)

	floIm = os.path.join(itDir,'DWsynth.nii.gz')
	resIm = os.path.join(itDir,'DWregged.nii.gz')
	cppName = os.path.join(itDir,'trans.cpp.nii')
	segResName = os.path.join(nextDir,'Segs_Diffspace.nii.gz')

	if not os.path.isfile(resIm) and os.path.isfile(floIm):
		DPD.NR_reg(refIm,floIm,cppName,resIm,rMask,dbg=False)

	segName = os.path.join(itDir,'Segs_Diffspace.nii.gz')
	if not os.path.isfile(segResName) and os.path.isfile(cppName):
		DPD.reg_resample(segName,segName,segResName,cpp = cppName,dbg = False)

	oldName = os.path.join(itDir,'reg_results.txt')
	newName = os.path.join(nextDir,'init_params.txt')
	if not os.path.isfile(newName) and os.path.isfile(oldName):
		shutil.copyfile(oldName,newName)


