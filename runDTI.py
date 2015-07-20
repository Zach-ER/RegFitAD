import os as os 

def binarise_mask(bMask,bMaskOut):
    return ' '.join(['fslmaths',bMask,'-bin',bMaskOut])

def dtifit(dwi,mask,bvals,bvecs,outPrefix):
    return ' '.join(['dtifit','-k',dwi,'-m',mask,'-b',bvals,'-r',bvecs,'-o',outPrefix])
    

subjIds = []

subjDir = '/scratch2/mmodat/ivor/nico/data/drc/Phil/cortical_diffusion'
#if not os.path.isdir(subjDir):
#    subjDir = '.'
outDir = '/home/zeatonro/RegFitAD/CortResults'
    
subjectList = os.path.join(subjDir,'subjects.txt')
subjectList = 'subjects.txt'

for line in open(subjectList): 
    ID =  line[0:4]
    
    resDir = os.path.join(outDir,'Res'+ID)
    
    DTdir = os.path.join(resDir,'DT')
    if not os.path.isdir(DTdir):
        os.makedirs(DTdir)
    
    BMname = os.path.join(resDir,'BMdiff.nii.gz')
    #name the binary mask file 
    BMout = os.path.join(resDir,'BMbin.nii.gz')

    #dwi filenames and boilerplate 
    dwiFile = os.path.join(subjDir,ID + '_corrected_dwi.nii.gz')
    bvecName =os.path.join(subjDir,ID + '_corrected_dwi.bvec')
    bvalName =os.path.join(subjDir,ID + '_corrected_dwi.bval')
    
    #need to copy bvals and bvecs, temporarily at least, to the results directory. 
    bvecTxt = os.path.join(DTdir,'bvecs.txt')
    bvalTxt = os.path.join(DTdir,'bvals.txt')
    
    instruc1 = binarise_mask(BMname,BMout)
    instruc2 = ' '.join(['cp',bvecName,bvecTxt,';','cp',bvalName,bvalTxt])
    
    outPrefix = os.path.join(DTdir,'DT');
    instruc3 = dtifit(dwiFile,BMout,bvalTxt,bvecTxt,outPrefix)

    if not os.path.isfile(outPrefix+'_FA.nii.gz'):
        os.system(instruc1)
        os.system(instruc2)
        os.system(instruc3)
