if [ -f $4 ];
then
	rm $4 tmp.nii.gz tmp_res.nii.gz
fi
for i in `seq 0 100`;
do
	seg_maths $1 -add 1 -equal $(($i+1)) -bin tmp.nii.gz
	if [ `seg_stats tmp.nii.gz -v` != "0" ];
	then
		echo Resampling label $i
	if [ -f $4 ];
		then 
			reg_resample -ref $2 -flo tmp.nii.gz -aff $3 -res tmp_res.nii.gz -psf -voff -inter 1 -pad 0
			seg_maths $4 -merge 1 4 tmp_res.nii.gz $4
		else
			reg_resample -ref $2 -flo tmp.nii.gz -aff $3 -res $4 -psf -voff -inter 1 -pad 1
		fi
	else
		echo Skipping label $i
		#seg_maths $2 -mul 0 tmp_res.nii.gz
	fi
done
rm tmp.nii.gz tmp_res.nii.gz