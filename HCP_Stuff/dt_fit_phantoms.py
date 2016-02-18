import os 
import shutil
import Diff_Preprocess_Defs as DPD
#This just does the DTI fitting for the phantoms. 
#Then it deletes the unneeded files. 

def get_immediate_subdirectories(a_dir):
    return [name for name in os.listdir(a_dir)
            if os.path.isdir(os.path.join(a_dir, name))]


def standard_dti_names(dwDIR):
	DWname = os.path.join(dwDIR,'DW_Resampled.nii.gz')
	MaskName = os.path.join(dwDIR,'Mask.nii.gz')
	bvalName = os.path.join(dwDIR,'bvals')
	bvecName = os.path.join(dwDIR,'bvecs')
	return DWname,MaskName,bvalName,bvecName

topDir = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/OneVoxCRB'

for dirName in get_immediate_subdirectories(topDir):
	if 'Readings' in dirName:
		readDir = os.path.join(topDir,dirName)
		for sampling in get_immediate_subdirectories(readDir):
			sampleDir = os.path.join(readDir,sampling)
			for it in get_immediate_subdirectories(sampleDir):

				itDir = os.path.join(sampleDir,it)
				dtOut = os.path.join(itDir,'DT')
				if not os.path.isdir(dtOut):
					os.makedirs(dtOut)
				DWname,MaskName,bvalName,bvecName = standard_dti_names(itDir)
				DPD.fit_diffusion_tensor(DWname,bvecName,bvalName,MaskName,dtOut+'/DT',wls=True,dbg=False)
					

	