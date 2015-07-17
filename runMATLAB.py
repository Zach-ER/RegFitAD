import os as os 

subjIds = []

subjDir = '/scratch2/mmodat/ivor/nico/data/drc/Phil/cortical_diffusion'
#if not os.path.isdir(subjDir):
#    subjDir = '.'
outDir = '/home/zeatonro/RegFitAD/CortResults'
    
subjectList = os.path.join(subjDir,'subjects.txt')
subjectList = 'subjects.txt'

for iName, line in enumerate(open(subjectList)): 
    ID =  line[0:4]    

    instrucs = []
    instrucs.append("#!/bin/bash -l")
    instrucs.append("#$ -S /bin/bash")
    instrucs.append("#$ -l h_rt=24:00:00")
    instrucs.append("#$ -l h_vmem=9.0G,tmem=8.0G")
    instrucs.append("#$ -N Subj" + ID )
    instrucs.append("#$ -j y")
    instrucs.append("#$ -R y")
    instrucs.append("#$ -wd /home/zeatonro/RegFitAD/code")

    scripName = 'fitScripts/runFit' + ID + '.sh'
    
    ID = "'" + ID+ "'"
    instrucs.append ('/share/apps/matlabR2013a/bin/matlab ' + 
    '-nodisplay -nodesktop -nosplash -singleCompThread -r "run_reg_fit_cluster(' +ID+')"')
    fh = open(scripName,'w')
    if iName > -1 :
        for line in instrucs:
            fh.write(line+'\n')
        fh.close()
        os.system('qsub ' + scripName)
