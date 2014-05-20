require 'redis'
require 'redis/bitops/queries/materialization_helpers'
require 'redis/bitops/queries/tree_building_helpers'
require 'redis/bitops/queries/lazy_evaluation'
require 'redis/bitops/queries/binary_operator'
require 'redis/bitops/queries/unary_operator'
require 'redis/bitops/bitmap'
require 'redis/bitops/sparse_bitmap'

require 'redis/bitops/configuration'


class Redis
  
  # Creates a new bitmap.
  #
  def bitmap(key)
    Bitops::Bitmap.new(key, self)
  end

  # Creates a new sparse bitmap storing data in n chunks to conserve memory.
  #
  def sparse_bitmap(key, bytes_per_chunk = nil)
    Bitops::SparseBitmap.new(key, self, bytes_per_chunk)
  end
end