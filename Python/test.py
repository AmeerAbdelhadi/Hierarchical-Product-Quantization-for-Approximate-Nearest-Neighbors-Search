import time
import math
import numpy as np

H  = int(math.ceil(math.log(2048,2)/math.log(32,2)))
print H
print math.ceil(H)
print int(math.ceil(H))

a = []

a.append(np.random.random((10, 2)).astype(np.uint8))
a.append(np.random.random((15, 3)).astype(np.uint8))
a.append(np.random.random((20, 4)).astype(np.uint8))

print a[0]
