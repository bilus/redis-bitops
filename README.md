TODO


+ Refactor the code. Fix the namespaces.
- YARD/rdoc documentation.
- Benchmark with reasonably large data.
- Find a reasonable size for chunk size.
- Write readme. 
  - Write about 3 phases: tree building, optimization, materialization.
  - <<
  - Assignment and lazy evaluation.
  - Configuration.
- Publish the gem.
- Search for places where ppl might need it and brag about it.

- DOCUMENT OR FIX: Correctly handle NOT so it doesn't set the extra bits. Explain why it occurs (redis byte boundary) and how it can be worked around using AND (plus maybe mention that in the field it's used it doesn't matter because NOT "from google" has to AND it with "all visitors" or otherwise it won't make sense.)


$redis = Redis.new

1. Bitmaps


2. Sparse bitmaps

b1 = SparseBitmap.new("version:1", $redis) # Optional connection.
b1.setbit(0, true)
b1.setbit(100, true)
b1[0] = true
b1[100] = true

b2 = SparseBitmap.new("source:google", $redis)
b2[0] = true
b2[5] = true


# Create a in-memory result.

result = b1 & !b2

# Save to a bitmap.

result.to_bitmap("version_1_not_from_google", $redis)


# Create a bitmap from expression.

b4 = SparseBitmap.new("version_1_from_google") do

end