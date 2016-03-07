import os 
import shutil
import Diff_Preprocess_Defs as DPD
import sys


def get_direc_name(sysArgs):
	if len(sysArgs) < 2:
		print 'Please include the top directory. Exiting'
		exit()
	else:
		return sysArgs[1]

def get_seg_name(sysArgs):
	if len(sysArgs) < 3:
		print 'Please include the segmentation name. Exiting'
		exit()
	else:
		return sysArgs[2]

topDir = get_direc_name(sys.argv)
diffSegName = get_seg_name(sys.argv)

gsDir = os.path.join(topDir,'GoldStand')
bvalName = os.path.join(gsDir,'bvals')
bvecName = os.path.join(gsDir,'bvecs')

for i in range(1,16):
	resampDir = os.path.join(gsDir,'downSampled_'+str(i))
	refName = os.path.join(resampDir,'Mask.nii.gz')
	outName = os.path.join(resampDir,'Segs_Resampled.nii.gz')
	floName = os.path.join(gsDir,diffSegName)
	
	if not os.path.isfile(outName):
		DPD.reg_resample(refName,floName,outName)

	outName = os.path.join(resampDir,'DW_Resampled.nii.gz')
	floName = os.path.join(gsDir,'DW.nii.gz')
	if not os.path.isfile(outName):
		DPD.reg_resample(refName,floName,outName)	

	shutil.copyfile(bvalName,os.path.join(resampDir,'bvals'))
	shutil.copyfile(bvecName,os.path.join(resampDir,'bvecs'))

	dtOut = os.path.join(resampDir,'DT')
	if not os.path.isdir(dtOut):
		os.makedirs(dtOut)
	if not os.path.isfile(dtOut+'/DT_MD.nii.gz'):
		DPD.fit_diffusion_tensor(outName,bvecName,bvalName,refName,dtOut+'/DT',wls=True,dbg=False)

	




