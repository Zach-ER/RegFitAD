import os 


def write_bash_cmd(jobName,T1_in,out_dir):
	sysCmd = 'name='+str(jobName)+';mkdir '+str(out_dir)+';qsub -l h_rt=36:00:00 -N GIF_${name} -o logs/GIF_${name}_output.txt -e logs/GIF_${name}_error.txt -l tmem=1.8G -l h_vmem=1.8G -pe smp 4 -R y -v OMP_NUM_THREADS=4 -l s_stack=10240  -j y -S /bin/csh -b y -cwd -V ~jmachado/install/bin/seg_GIF -in ' + str(T1_in) +' -db /home/jmachado/NewGIFDB/db.xml -v 1 -out '+str(out_dir)+' -temper 0.05 -lncc_ker -5' 
	return sysCmd


T1Dir = '/home/zeatonro/HCP_Data/'
T1Name = os.path.join(T1Dir,'T1w_acpc_dc_restore.nii.gz')
jobName= 'T1_Seg'
out_dir = os.path.join(T1Dir,jobName)
sysCmd  = write_bash_cmd(jobName,T1Name,out_dir)
print(sysCmd)
			





