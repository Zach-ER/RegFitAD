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
	if len(sysArgs) < 6:
		print 'Please include the segmentation name and outnames. Exiting'
		exit()
	else:
		return sysArgs[2],sysArgs[3],sysArgs[4],sysArgs[5]

def do_i_dtifit(sysArgs):
	if len(sysArgs) < 7:
		print 'Do you want to do DTI fitting? Exiting'
		exit()
	else:
		return sysArgs[6]
	

topDir = get_direc_name(sys.argv)
diffSegName,segOutName,DWoutName, maskName = get_seg_name(sys.argv)
#true or false 
dtiCode = do_i_dtifit(sys.argv)

gsDir = os.path.join(topDir,'GoldStand')
bvalName = os.path.join(gsDir,'bvals')
bvecName = os.path.join(gsDir,'bvecs')

for i in range(1,16):
	resampDir = os.path.join(gsDir,'downSampled_'+str(i))
	refName = os.path.join(resampDir,maskName)
	outName = os.path.join(resampDir,segOutName)
	floName = os.path.join(gsDir,diffSegName)
	
	if not os.path.isfile(outName):
		DPD.reg_resample(refName,floName,outName,other_args = '-psf')

	outName = os.path.join(resampDir,DWoutName)
	floName = os.path.join(gsDir,'DW.nii.gz')
	if not os.path.isfile(outName):
		DPD.reg_resample(refName,floName,outName,other_args = '-psf')	

	shutil.copyfile(bvalName,os.path.join(resampDir,'bvals'))
	shutil.copyfile(bvecName,os.path.join(resampDir,'bvecs'))

	if not dtiCode == '0':
		dtOut = os.path.join(resampDir,'DT')
		if not os.path.isdir(dtOut):
			os.makedirs(dtOut)
		if not os.path.isfile(dtOut+'/DT_MD.nii.gz'):
			DPD.fit_diffusion_tensor(outName,bvecName,bvalName,refName,dtOut+'/DT',wls=True,dbg=False)

	




