import math
import random
import csv
import operator

# generate CSV file with random float numbers
# N D-dimensional vectors splitted by 'delim' and written to csv file 'fn'
def genRandCSV(N, D, delim, fn):
	random.random()
	row = []
	with open(fn, 'w') as csvfile:
		writer = csv.writer(csvfile, delimiter=delim)
		for irow in range(N):
			for icol in range(D):
				row.append(random.random())
			writer.writerow(row)
			row=[];
	csvfile.close()

# read csv to matrix.
# returns a 2d matrix
def CSV2Matrix(fn):
	mat = []
	with open(fn, 'rb') as csvfile:
		lines = csv.reader(csvfile)
		dataset = list(lines)
		D = len(dataset[0])
		N = len(dataset)
		for x in range(N):
			for y in range(D):
				dataset[x][y] = float(dataset[x][y])
			mat.append(dataset[x])
	return mat

# computes euclidean distance between two equl-dimension vectors
def euclideanDist(v1, v2):
	# compute euclidean distance
	dist = 0
	for i in range(len(v1)):
		dist += pow((v1[i] - v2[i]), 2)
	return math.sqrt(dist)

# compute cosine similarity of two equl-dimension vectors v1 to v2
# COSSIM = (v1 dot v2)/(||v1||*||v2||)
def cosineSim(v1,v2):
	Sxx, Sxy, Syy = 0, 0, 0
	for i in range(len(v1)):
		Sxx += v1[i]*v1[i]
		Syy += v2[i]*v2[i]
		Sxy += v1[i]*v2[i]
	return Sxy/math.sqrt(Sxx*Syy)

# find k-nearest neighbours of qVec in the database vecDB using simFunc for compares
def KNN_ES(vecDB, qVec, k, simFunc):
	dists = []
	D = len(qVec)
	N = len(vecDB)
	for i in range(N):
		dist = simFunc(qVec, vecDB[i])
		dists.append((vecDB[i], dist))
	dists.sort(key=operator.itemgetter(1))
	neighbors = []
	for i in range(k):
		neighbors.append(dists[i][0])
	return neighbors

# test
def main():
	# prepare data
	genRandCSV(100000,8,',','vecdb.csv')
	genRandCSV(10,8,',','qvecs.csv')
	vecDB=CSV2Matrix('vecdb.csv')
	qVecs=CSV2Matrix('qvecs.csv')
	k = 8
	for x in range(len(qVecs)):
		print 'Query Vector:'
		print repr(qVecs[x])
		neighbors = KNN_ES(vecDB, qVecs[x], k, cosineSim)
		print repr(k)+'-Nearest Neighbors:'
		for j in range(k):
			print repr(neighbors[j])
		print
	
main()
