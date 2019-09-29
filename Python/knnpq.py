import numpy as np
from scipy.cluster.vq import vq, kmeans2
from datetime import datetime
import time
import random
import math
import operator

from mpl_toolkits.mplot3d import Axes3D
import matplotlib
matplotlib.use('Agg') # prevents interactive plots
import matplotlib.pyplot as plt

"""
N : Database size
D : Space dimension
M : the number of subspaces (subquantizers)
Dt: The dimension of each sub-vector, i.e., Ds=D/M
Kt: the number of sub-codewords in each subspace
alpha: tappering factor
Y : a set of data points
C : codebook
	Cc: centroids in codebook
	Cn: number of point attched to the centroid
	Cd: distances between centroid and a query
Yt : encoded dataset Y; the set of vector indecies assigned to the sub-codeword in C
"""

class PQ(object):

	# initialize PQ class
	def __init__(self, N, D, M, Kt, alpha=64, dtype=np.float32, readcsv=True, writecsv=True, verbose=False, plot=False, dump=False):
		# parameter checks
		assert D % M == 0, 'equally divided sub-spaces are required; make sure M divides D'
		assert Kt <= N, 'Kt, the number of sub-codewords in each subspace, should be smaller than the number of the database vectors'
		assert 0 < Kt <= 2 ** 32, 'codebook should be smaller than 2**32'
		assert 0 < alpha, 'tappering factor should be a positive number'
		# assign parameters
		self.N = N
		self.D = D
		self.M = M
		self.Dt = D/M
		self.Kt = Kt
		self.H  = int(math.ceil(math.log(2048,2)/math.log(32,2)))

		# code index type, based on the codebook length 'Kt'
		self.ctype = ((np.uint32,np.uint16)[Kt<=2**16],np.uint8)[Kt<=2**8]

		# data index type, based on the length 'N'
		self.itype = ((np.uint32,np.uint16)[N<=2**16],np.uint8)[N<=2**8]

		# data type
		self.dtype = dtype

		# C: create 3d matrix of centroid codes: [M subspaces][Kt codewords][Dt dim of subspace] centroids codebook
		self.Cc  = np.zeros((self.M, self.Kt, self.Dt), dtype=self.dtype) 
		self.Cn = np.zeros((self.M, self.Kt         ), dtype=self.itype) # number of points attached to each centroid
		self.Cd = np.zeros((self.M, self.Kt         ), dtype=self.dtype) # distances between sub-query vector and each centroid

		# Yt: create 2d matrix of code index per sub-vector: [M subspaces][N vectors] encoded input vectors
		self.Yt = np.zeros((self.N, self.M        ), dtype=self.ctype )

		# create 3d matrix of code indicators per sub-vector: [M subspaces][k codewords][N vector addresses]
		self.I = np.zeros((self.M, self.Kt, self.N), dtype=np.uint8 )


		self.readcsv = readcsv
		self.writecsv = writecsv
		self.verbose = verbose
		self.plot = plot
		if verbose:
			print 'PQ class parameters: N:',N,', D:',D,', M:',M,', Dt:',self.Dt,', Kt: ',Kt,', ctype:',self.ctype

	##########################################

	# construct the PQ databased
	def construct(self, Y, kmcIter=20,kmcSeed=7):
		# checks on vectors DB
		assert Y.ndim     == 2         , 'Vectors database should be a two dimensional matrix'
		assert Y.shape[0] == self.N    , 'Vectors database should have N vectors'
		assert Y.shape[1] == self.D    , 'Vectors in database should be D-dimensional'
		assert Y.dtype    == self.dtype, 'Vector type should be self.dtype'

		if self.verbose:
			print 'K-means clustering iterations#: '+repr(kmcIter)

		if self.writecsv:
			np.savetxt(str(self.N)+'x'+str(self.D)+'-M'+str(self.M)+'-Kt'+str(self.Kt)+'-X'+'.csv', Y, delimiter=',')

		# random seed for kmeams clustering 
		np.random.seed(kmcSeed)

		# find k-means for each one of the M subspaces
		for m in range(self.M):

			if self.verbose:
				print 'k-means clustering for subspace:',m+1,'/',self.M

			# slice vector database into the m-th subspace
			Y_sub = Y[:, m*self.Dt : (m+1)*self.Dt]

			# generate k-means for this subspace
			self.Cc[m], self.Yt[:,m] = kmeans2(Y_sub, self.Kt, iter=kmcIter, minit='points')
			if self.writecsv:
				np.savetxt(str(self.N)+'x'+str(self.D)+'-M'+str(self.M)+'-K'+str(self.Kt)+'-Z'+str(m)+'.csv', self.Cc[m], delimiter=',')

			# assign indicators matrix for each subspace
			for ki in range(self.Kt):
				for ni in range(self.N):
					if self.Yt[ni,m]==ki:
						self.I[m,ki,ni]=1
						self.Cn[m,ki]+=1

			if self.plot and (self.Dt==2 or self.Dt==3):
				print 'plotting a figure for point and centroids of subspace '+repr(m)+' / '+repr(self.M)+' in figure '+'./kmeans'+repr(m)+' ...'
				# colors for different centroids
				colors  = ([('#e6194b', '#3cb44b', '#ffe119', '#4363d8', '#f58231', '#911eb4', '#46f0f0', \
                             '#f032e6', '#bcf60c', '#fabebe', '#008080', '#e6beff', '#9a6324', '#800000', \
                             '#aaffc3', '#808000', '#ffd8b1', '#000075', '#808080', '#ffffff'               )[i] for i in self.Yt[:,m]])

				fig = plt.figure()
				if self.Dt==2:
					ax = fig.add_subplot(111)
					# plot colored points
					ax.scatter(Y_sub[:,0],Y_sub[:,1], marker='o', c=colors)
					# mark centroids as circuled X's
					ax.scatter(self.Cc[m,:,0],self.Cc[m,:,1], marker='o', s=500, linewidths=2, c='none')
					ax.scatter(self.Cc[m,:,0],self.Cc[m,:,1], marker='x', s=500, linewidths=2)
				if self.Dt==3:
					ax = fig.add_subplot(111, projection='3d')
					# plot colored points
					ax.scatter(Y_sub[:,0],Y_sub[:,1],Y_sub[:,2], marker='o', c=colors)
					# mark centroids as circuled X's
					ax.scatter(self.Cc[m,:,0],self.Cc[m,:,1],self.Cc[m,:,2], marker='o', s=500, linewidths=2, c='none')
					ax.scatter(self.Cc[m,:,0],self.Cc[m,:,1],self.Cc[m,:,2], marker='x', s=500, linewidths=2)
				# plot as png figure for each sub-space
				fig.savefig('./kmeans'+repr(m)+'.png')
				plt.close(fig)    # close the figure
		if self.writecsv:
			np.savetxt(str(self.N)+'x'+str(self.D)+'-M'+str(self.M)+'-K'+str(self.Kt)+'-C'+'.csv', self.Yt, fmt='%4d', delimiter=',')
		return self

	# vectors batch quantization
	def qvec_(self, vecs):
		# checks on vectors DB
		assert vecs.ndim     == 2         , 'Vectors database should be a two dimensional matrix'
		assert vecs.shape[1] == self.D    , 'Vectors in database should be D-dimensional'
		assert vecs.dtype    == self.dtype, 'Vector type should be self.dtype'
		Nq = vecs.shape[0] # number of query vectors
		# qcodes[n][m] : code of n-th vec, m-th subspace
		qcodes = np.empty((Nq, self.M), dtype=self.ctype)
		for m in range(self.M):
			if self.verbose:
				print("Encoding the subspace: {} / {}".format(m, self.M))
			vecs_sub = vecs[:, m * self.Dt : (m+1) * self.Dt]
			qcodes[:, m], _ = vq(vecs_sub, self.codewords[m])
		return qcodes

	# update distances based on query vector
	def udist(self, qvec):
		for m in range(self.M):
			for k in range(self.Kt):
				qvec_sub = qvec[m*self.Dt : (m+1)*self.Dt]
				self.Cd[m,k]= self.euclideanDistSqr(self.Cc[m,k],qvec_sub)
		return self

	def prune(self, qvec):
		self.udist(qvec)
		mini = 0
		mina = [self.Cd[m,self.Yt[mini,m]] for m in range(self.M)]
		mind = sum(mina)
		pruned=0
		for n in range(1,self.N):
			cura = [self.Cd[m,self.Yt[n,m]] for m in range(self.M)]
			curd = sum(cura)
			if np.all(np.greater_equal(cura,mina)):
				pruned+=1
			if (curd<mind):
				mini=n
				mina=cura
				mind=curd
		return pruned
				
	def pruneMulti(self, qvec, k):
		self.udist(qvec)
		mini = np.zeros((k       ), dtype=self.itype)
		mina = np.zeros((k,self.M), dtype=self.dtype)
		mind = np.zeros((k       ), dtype=self.dtype)
		for ki in range(k):
			mini[ki] = ki
			mina[ki] = [self.Cd[m,self.Yt[mini[ki],m]] for m in range(self.M)]
			mind[ki] = sum(mina[ki])
		pruned=0
		for n in range(k,self.N):
			cura = [self.Cd[m,self.Yt[n,m]] for m in range(self.M)]
			curd = sum(cura)
			if np.any([np.all(np.greater_equal(cura,mina[ki])) for ki in range(k)]):
				pruned+=1
			maxi=np.argmax(mind)
			if (curd<mind[maxi]):
				mini[maxi]=n
				mina[maxi]=cura
				mind[maxi]=curd
		return pruned

	# KNN-PQ-ES query
	def knnpqes(self, qvec, k):
		dist = np.zeros((self.N), dtype=self.dtype)
		#dSum = np.zeros((self.N), dtype=self.dtype)
		self.udist(qvec)
		for n in range(self.N):
		#	for m in range(self.M):
		#		dist[n] += self.Cd[m,self.Yt[n,m]]
			dist[n] = sum([self.Cd[m,self.Yt[n,m]] for m in range(self.M)])
		kmax = dist.argsort()[:k]
		return kmax

	# KNN-PQ-ES query / selective search indices
	def knnpqes_sel(self, qvec, k, sidx):
		dist = np.full((self.N), np.finfo(self.dtype).max, self.dtype)
		#dSum = np.zeros((self.N), dtype=self.dtype)
		self.udist(qvec)
		for n in sidx:
		#	for m in range(self.M):
		#		dist[n] += self.Cd[m,self.Yt[n,m]]
			dist[n] = sum([self.Cd[m,self.Yt[n,m]] for m in range(self.M)])
		kmax = dist.argsort()[:k]
		return kmax

	#def knnhpq(self, qvec, k):


	def update(self, uvec, uidx):
		for m in range(self.M):
			uvec_sub = uvec[m*self.Dt : (m+1)*self.Dt]
			cid,_,_ = self.knnes(self.Cc[m],uvec_sub,1,self.euclideanDistSqr)
			self.I[m,self.Yt[uidx,m],uidx]=0
			self.Yt[uidx,m]=cid
			self.I[m,cid,uidx]=1
		return self

	def query(self, qvec, k, kc):
		indcs = np.zeros((self.M, kc, self.N), dtype=np.uint8  )
		indcs_ = np.zeros((self.M, kc, self.N), dtype=self.dtype)
		cid   = np.zeros((self.M, kc        ), dtype=self.ctype)
		dists = np.zeros((self.M, kc        ), dtype=self.dtype)
		inf = 2
		for m in range(self.M):
			qvec_sub = qvec[m*self.Dt : (m+1)*self.Dt]
			cid[m],_,dists[m] = self.knnes(self.Cc[m],qvec_sub,kc,self.euclideanDistSqr)
			indcs[m][:] = self.I[m][cid[m][:]]
			for kci in range(kc):
				indcs_[m][kci] = self.I[m][cid[m][kci]]*dists[m][kci]
		indcs_[indcs_==0] = inf
		iOR = np.zeros((self.M,self.N), dtype=np.uint8)
		iOR = np.min(indcs_,axis=1)
		iSum = np.zeros((self.N), dtype=np.uint8)
		iSum = np.sum(iOR,axis=0)
		#kmax = iSum.argsort()[-k:][::-1]
		kmax = iSum.argsort()[:k]
		return indcs, indcs_, dists, iOR, iSum, kmax

	# KNN-ES
	# find k-nearest neighbours of qVec in the database Y using simFunc for compares
	def knnes(self, Y, qVec, k, simFunc):
		vInfo = []
		D = len(qVec)
		N = len(Y)
		for i in range(N):
			dist = simFunc(qVec, Y[i])
			vInfo.append((i, Y[i], dist))
		vInfo.sort(key=operator.itemgetter(2))
		#neighbors = []
		ids       = np.zeros((k   ), dtype=np.uint32 )
		neighbors = np.zeros((k, D), dtype=self.dtype)
		dists     = np.zeros((k   ), dtype=self.dtype)
		for i in range(k):
			ids[i]       = vInfo[i][0]
			neighbors[i] = vInfo[i][1]
			dists[i]     = vInfo[i][2]
		return ids, neighbors, dists

	# computes euclidean distance between two equl-dimension vectors
	def euclideanDist(self,v1, v2):
		# compute euclidean distance
		dist = 0
		for i in range(len(v1)):
			dist += pow((v1[i] - v2[i]), 2)
		return math.sqrt(dist)

	def euclideanDistSqr(self,v1, v2):
		# compute euclidean distance
		dist = 0
		for i in range(len(v1)):
			dist += pow((v1[i] - v2[i]), 2)
		return dist

	# compute cosine similarity of two equl-dimension vectors v1 to v2
	# COSSIM = (v1 dot v2)/(||v1||*||v2||)
	def cosineSim(self,v1,v2):
		Sxx, Sxy, Syy = 0, 0, 0
		for i in range(len(v1)):
			Sxx += v1[i]*v1[i]
			Syy += v2[i]*v2[i]
			Sxy += v1[i]*v2[i]
		return Sxy/math.sqrt(Sxx*Syy)

