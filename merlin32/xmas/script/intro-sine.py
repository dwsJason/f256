import math
# for d in range(0,91,2):
# 	r= math.radians(d)
# 	v= math.cos(r)
# 	print(v, int(v*240))

# for d in range(0,181,2):
# 	r= math.radians(d)
# 	v= math.sin(r)
# 	print(v, int(v*200))

# scale list by scale amount
def scale_to(x, scale):
	return [element * scale for element in x]

# turn list to ints
def intify(x):
	return [int(element) for element in x]

# start degrees, end degrees, num points
def get_sin_range(start, end, points):
	return get_sin_cos_range(start, end, points, 'sin')

def get_cos_range(start, end, points):
	return get_sin_cos_range(start, end, points, 'cos')

def get_sin_cos_range(start, end, points, sincos="sin"):
	rs = []
	for v in range(points+1):
		diff = end - start
		deg_add = v*diff/points
		degree = start + deg_add
		r = math.radians(degree)
		if sincos=="sin":
			rs.append(math.sin(r))
		else:
			rs.append(math.cos(r))

	return rs

def print_chunked(data, chunk_len, line_pfx):
	# chunk_size = 512
	chunks = [data[i:i + chunk_len] for i in range(0,len(data), chunk_len)]
	for c in chunks:
		print(line_pfx, end='')
		formatted = [f'${element:06x}' for element in c]
		print(','.join(formatted))

# print(get_sin_range(0,180,20))
# print(intify(scale_to(get_sin_range(0,180,20),240)))

bounce_vals = []
bounce_vals.extend(intify(scale_to(get_sin_range(90,180,50),240)))
bounce_vals.extend(intify(scale_to(get_sin_range(0,180,100),180))[1:])	#[1:] to dedupe 0 values since we start/end at same/opposite angle
bounce_vals.extend(intify(scale_to(get_sin_range(0,180,90),120))[1:])
bounce_vals.extend(intify(scale_to(get_sin_range(0,180,80),60))[1:])
print(bounce_vals)
print()

bounce_offsets = [320*(element) for element in bounce_vals]
print(bounce_offsets)
print()

print_chunked(bounce_offsets,10,"  adr ")


