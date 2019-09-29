import time
import math
import knnpq
import numpy as np

import matplotlib
matplotlib.use('Agg') # prevents interactive plots

import matplotlib.pyplot as plt

#np.set_printoptions(precision=2, suppress=True)
np.set_printoptions(formatter={'float': '{: 0.2f}'.format})
#from labellines import labelLine, labelLines

def get_cmap(n, name='hsv'):
    '''Returns a function that maps each index in 0, 1, ..., n-1 to a distinct 
    RGB color; the keyword argument name must be a standard mpl colormap name.'''
    return plt.cm.get_cmap(name, n)

#seed = int(time.time())
seed = 7
np.random.seed(seed)

dtype=np.float32


lN = 10
lD = 6
lM = 4
# generate N random D-dimensional vectors
X = np.random.random((2**lN, 2**lD)).astype(dtype)

# generate Q random D-dimensional query vectors
Q = 10
qV = np.random.random((Q, 2**lD)).astype(dtype)

# generate U random D-dimensional update vectors
U = 1000

R= [10**i for i in range(int(math.log10(2**lN))+1)]
print R

lK = 4

recall = np.zeros((lK+1, len(R)), dtype=np.float16)

cmap = get_cmap(lK+1)

# instantiate with N D-dimensional vectors, M sub-spaces, and K-words codebooks
pq = knnpq.PQ(N=2**lN, D=2**lD, M=2**lM, Kt=2**lK, dtype=dtype, readcsv=False, writecsv=False, verbose=True, plot=False, dump=True)

# construct database with X
pq.construct(X,kmcIter=20,kmcSeed=seed)

kc = 2**lK


for iii in range(4):

	##print 'qV:',qV

	#print pq.I
	#print 'ids:'
	#print ids
	found = [0]*len(R)
	for qi in range(Q):
		ids, neighbors, dists = pq.KNNES(X,qV[qi],pq.N,pq.euclideanDistSqr);
		#print 'neighbors:',ids,'-',neighbors,'-',dists
		#for ii in range(10):
			#print 'ids[:ii*10]-',ii+1,ids[:ii*10+10]

		#indicators, isum, kmax = pq.query(qV[qi], 1)
		indicators, indc_, dists_, iOR, iSum, kmax = pq.query(qV[qi], 1, kc)
		for i in range(len(R)):
			if kmax[0] in ids[:R[i]]:
				print '.',
				found[i]+=1
			else:
				print 'X',
		print
	"""
		print 'indicators:'
		print indicators
		print 'indc_:'
		print indc_
		print 'dists_:'
		print dists_
		print 'iOR:'
		print iOR
		print 'iSUM:',iSum
		print 'kmax:',kmax
	"""
	recall_ = [i/float(Q) for i in found]
	recall[lK] = recall_
	print 'Recall@', R, '=', recall_

	print 'updating',U,'vectors'
	uV = np.random.random((U, 2**lD)).astype(dtype)
	uI = np.random.random((U)).astype(np.uint32)
	for j in range(U):
		pq.update(uV[j],uI[j])

	#plt.plot(R,recall_,c=cmap(lK),label='k='+str(2**lK))

	#print 'Recall@'+str(R),'=', found, '/', Q, '=', found/float(Q)
	#print isum
	#print kmax[0]
	#print qv
	#print ids[0]
	#print kmax[0]
	#print X[ids[0]]
	#print X[kmax[0]]
"""
np.savetxt(str(pq.N)+'x'+str(pq.D)+'-M'+str(pq.M)+'-R'+'.csv', recall, fmt='%.4f', delimiter=',')

plt.legend(loc='upper left')
plt.xscale('log')
plt.title('Recall@R '+str(pq.N)+'x'+str(pq.D)+', M='+str(pq.M))
plt.xlabel('R')
plt.ylabel('Recalls')
plt.grid(True)
#plt.show()
plt.savefig(str(pq.N)+'x'+str(pq.D)+'-M'+str(pq.M)+'-R'+'.png')
"""

