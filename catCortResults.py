fh1= open('resultsList.txt','r')
fh2= open('allResults.txt','w')
for subj in fh1:
	fh = open(subj[:-1],'r')
        for iLine,line in enumerate(fh):
		subjHand = subj.split('/')[2][-4:]
		new_line = '    '.join([subjHand,str(iLine+1).zfill(2),line])
		fh2.write(new_line)

fh1.close()
fh2.close()	
