import time
import math
import knnpq
import numpy as np
from scipy.cluster.vq import vq, kmeans2

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


lN    = 12
lD    = 4
lM    = 2
alpha = 64
# generate N random D-dimensional vectors
Y = []
Y.append(np.random.random((2**lN, 2**lD)).astype(dtype))

# generate Q random D-dimensional query vectors
Q = 100
qV = np.random.random((Q, 2**lD)).astype(dtype)

R= [10**i for i in range(int(math.log10(2**lN))+1)]
print R

#lK_list = [4,5,6,7,8]
lK_list = [4,5,6]
w=1

recall = np.zeros((max(lK_list)+1, len(R)), dtype=np.float16)

cmap = get_cmap(max(lK_list)+1)

for lK in lK_list:
	pq = []
	print lK
	# instantiate with N D-dimensional vectors, M sub-spaces, and K-words codebooks
	pq.append(knnpq.PQ(N=2**lN, D=2**lD, M=2**lM, Kt=2**lK, dtype=dtype, readcsv=False, writecsv=False, verbose=True, plot=False, dump=True))

	# construct database with Y[0]
	pq[0].construct(Y[0],kmcIter=20,kmcSeed=seed)

################

	Cc_ = np.zeros((2**lK,2**lD), dtype=dtype    ) 
	Yt_ = np.zeros((2**lN/alpha), dtype=np.uint16)
	Cc_, Yt_ = kmeans2(Y[0], 2**lN/alpha, iter=20, minit='points')
	Y.append(Cc_)
	pq.append(knnpq.PQ(N=2**lN/alpha, D=2**lD, M=2**lM, Kt=2**lK, dtype=dtype, readcsv=False, writecsv=False, verbose=True, plot=False, dump=True))
	pq[1].construct(Y[1],kmcIter=20,kmcSeed=seed)

	#print "Cc_:"
	#print Cc_
	#print "Yt_:"
	#print Yt_

############

	kc = 2**lK

	"""
	print 'X:'
	print X
	"""


	"""
	for m in range(pq.M):
		print 'm='+str(m)
		for k in range(pq.K):
			print 'k='+str(k)+":"+str(pq.Z[m][k])+'-'+str(pq.I[m][k])
	"""

	##print 'qV:',qV

	#print pq.I
	#print 'ids:'
	#print ids
	found = [0]*len(R)
	for qi in range(Q):

###########
		ids_, neighbors_, dists_ = pq[1].knnes(Cc_,qV[qi],w,pq[1].euclideanDistSqr);
		#print 'qV'
		#print qV[qi]
		#print 'ids_'
		#print ids_
		#print 'neighbors_'
		#print neighbors_
		#print 'dists_'
		#print dists_
		match = []
		for i in range(pq[0].N):
			for j in range(w):
				if Yt_[i] == ids_[j]:
					match.append(i)
		#print 'match:'
		#print len(match)
		#print match

###########
		ids, neighbors, dists = pq[0].knnes(Y[0],qV[qi],pq[0].N,pq[0].euclideanDistSqr);
		#print 'neighbors:',ids,'-',neighbors,'-',dists
		#for ii in range(10):
			#print 'ids[:ii*10]-',ii+1,ids[:ii*10+10]

		#indicators, isum, kmax = pq.query(qV[qi], 1)
		#kmax = pq.knnpqes(qV[qi], 1)
		kmax = pq[0].knnpqes_sel(qV[qi], 1, match)
		#indicators, indc_, dists_, iOR, iSum, kmax = pq.query(qV[qi], 1, kc)
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

	plt.plot(R,recall_,c=cmap(lK),label='k*='+str(2**lK))
	#print 'Recall@'+str(R),'=', found, '/', Q, '=', found/float(Q)
	#print isum
	#print kmax[0]
	#print qv
	#print ids[0]
	#print kmax[0]
	#print Y[ids[0]]
	#print Y[kmax[0]]

np.savetxt(str(pq[0].N)+'x'+str(pq[0].D)+'-M'+str(pq[0].M)+'-R'+'.csv', recall, fmt='%.4f', delimiter=',')

plt.legend(loc='upper left')
plt.xscale('log')
plt.title('Recall@R '+str(pq[0].N)+'x'+str(pq[0].D)+', M='+str(pq[0].M))
plt.xlabel('R')
plt.ylabel('Recalls')
plt.grid(True)
#plt.show()
plt.savefig(str(pq[0].N)+'x'+str(pq[0].D)+'-M'+str(pq[0].M)+'-R'+'.png')


