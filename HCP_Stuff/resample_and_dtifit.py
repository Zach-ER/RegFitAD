import os 
import shutil
import Diff_Preprocess_Defs as DPD

topDir = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/OneVoxCRB'
gsDir = os.path.join(topDir,'GoldStand')

bvalName = os.path.join(gsDir,'bvals')
bvecName = os.path.join(gsDir,'bvecs')

for i in range(1,16):
	resampDir = os.path.join(gsDir,'downSampled_'+str(i))
	refName = os.path.join(resampDir,'Mask.nii.gz')
	outName = os.path.join(resampDir,'Segs_Resampled.nii.gz')
	floName = os.path.join(gsDir,'Segs_Reduced.nii.gz')
	
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

		#Using the subject directory instead. 
	bvalName = os.path.join(resampDir,'bvals')
	bvecName = os.path.join(resampDir,'bvecs')
	exp_ext = ''	
	#dtOut = '_'.join([dtOut,exp_ext])
	if not os.path.isdir(dtOut):
		os.makedirs(dtOut)
	#if not os.path.isfile(dtOut+'/DT_MD.nii.gz'):
	DWname = os.path.join(resampDir,'DW_Resampled.nii.gz') #DWname = os.path.join(resampDir,'DW_'+exp_ext+'.nii.gz')
	DPD.fit_diffusion_tensor(DWname,bvecName,\
		bvalName,refName,dtOut+'/DT',wls=True,dbg=False)

	#DPD.fit_diffusion_tensor(DWname,'_'.join([bvecName,exp_ext]),\
	#	'_'.join([bvalName,exp_ext]),refName,dtOut+'/DT',wls=True,dbg=False)

