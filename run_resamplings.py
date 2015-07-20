import os as os 

def reg_resample_psf(ref,flo,aff,res):
    return ' '.join(['reg_resample','-ref',ref,'-flo',flo,'-aff',aff,'-res',res,'-psf -inter 1'])
    

subjIds = []

subjDir = '/scratch2/mmodat/ivor/nico/data/drc/Phil/cortical_diffusion'
if not os.path.isdir(subjDir):
    subjDir = '.'
jorgeDir = '/home/jmachado/DataToRunGIF/ZachMine'
outDir = '/home/zeatonro/RegFitAD/CortResults'
    
subjectList = os.path.join(subjDir,'subjects.txt')

for line in open(subjectList): 
    subjId =  line[0:4]
    newDir = os.path.join(outDir,'Res'+subjId)
    #os.makedirs(newDir)
    subjIds.append(subjId)
    
for ID in subjIds[13:]:
    resDir = os.path.join(outDir,'Res'+ID)
    
    affFile = os.path.join(subjDir,ID + '_B0_to_T1.txt')
    freeSurfer = os.path.join(subjDir,ID + '_labels.nii.gz')
    dwiFile = os.path.join(subjDir,ID + '_corrected_dwi.nii.gz')
    FAFile = os.path.join(resDir,'DT','DT_FA.nii.gz')
    
    GIFdir = os.path.join(jorgeDir,ID+'_T1')
    BMname = os.path.join(GIFdir,ID+'_T1_NeuroMorph_Brain.nii.gz')
    segName = os.path.join(GIFdir,ID+'_T1_NeuroMorph_Segmentation.nii.gz')
    parcelName = os.path.join(GIFdir,ID+'_T1_NeuroMorph_Parcellation.nii.gz')
    
    FSout = os.path.join(resDir,'LabsDiff.nii.gz')
    BMout = os.path.join(resDir,'BMdiff.nii.gz')
    segOut = os.path.join(resDir,'SegDiff.nii.gz') 
    parcelOut = os.path.join(resDir,'ParcelDiff.nii.gz') 
    
    all_lines = []
    all_lines.append(reg_resample_psf(dwiFile,BMname,affFile,BMout) + '\n')
    all_lines.append(reg_resample_psf(dwiFile,segName,affFile,segOut)+ '\n')    
    all_lines.append(' '.join(['cd',resDir,'\n']))
    all_lines.append(' '.join(['sh /home/zeatonro/RegFitAD/code/script.sh ',freeSurfer,FAFile,affFile,FSout]) + '\n')

    scripName = 'regScripts/scrip' + ID + '.sh'
    fh = open(scripName,'w')
    for line in all_lines:
        fh.write(line)
    fh.close()

    if not os.path.isfile(FSout):
        os.system('qsub -l h_rt=1:00:00 -l tmem=4G -l h_vmem=4G -l vf=4G -j y -S /bin/sh -b y -cwd -V -N ' + 'subj'+ ID + ' sh ' + scripName)

