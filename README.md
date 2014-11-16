# Introduction

This gem makes it easier to do bit-wise operations on large Redis bitsets, usually called bitmaps, with a natural expression syntax. It also supports huge **sparse bitmaps** by storing data in multiple keys, called chunks, per bitmap.

The typical use is real-time web analytics where each bit in a bitmap/bitset corresponds to a user ([introductory article here](http://blog.getspool.com/2011/11/29/fast-easy-realtime-metrics-using-redis-bitmaps/)). This library isn't an analytic package though, it's more low level than that and you can use it for anything. 

**This library is under development and its interface might change.**


# Quick start/pitch

Why use the library?

    require 'redis/bitops'
    redis = Redis.new

    b1 = redis.sparse_bitmap("b1")
    b1[128_000_000] = true
    b2 = redis.sparse_bitmap("b2")
    b2[128_000_000] = true
    result = b1 & b2

Memory usage: about 20kb because it uses a sparse bitmap implementation using chunks of data.

Let's go crazy with super-complicated expressions:

    ...
    result = (b1 & ~b2) | b3 (b4 | (b5 & b6 & b7 & ~b8))

Imagine writing this expression using Redis#bitop!


# Installation

To install the gem:

    gem install redis-bitops

To use it in your code:

    require 'redis/bitops'

# Usage

Reference: [here](http://rdoc.info/github/bilus/redis-bitops/master/frames)

## Basic example

An example is often better than theory so here's one. Let's create a few bitmaps and set their individual bits; we'll use those bitmaps in the examples below:

    redis = Redis.new

    a = redis.bitmap("a")
    b = redis.bitmap("b")
    result = redis.bitmap("result")

    b[0] = true; b[2] = true; b[7] = true # 10100001
    a[0] = true; a[1] = true; a[7] = true # 11000001

So, now here's a very simple expression:

    c = a & b

You may be surprised but the above statement does not query Redis at all! The expression is lazy-evaluated when you access the result:

    puts c.bitcount # => 2
    puts c[0] # => true
    puts c[1] # => false
    puts c[2] # => false
    puts c[7] # => false

So, in the above example, the call to `c.bitcount` happens to be the first moment when Redis is queried. The result is stored under a temporary unique key.

    puts c.root_key # => "redis:bitops:8eef38u9o09334"

Let's delete the temporary result:

    c.delete!

If you want to store the result directly under a specific key:

    result << c

Or, more adventurously, we can use the following more complex one-liner:

    result << (~c & (a | b))

**Note: ** expressions are optimized by reducing the number of Redis commands and using as few temporary keys to hold intermediate values as possible. See below for details.


## Sparse bitmaps

### Usage

You don't have to do anything special, simply use `Redis#sparse_bitmap` instead of `Redis#bitmap`:

    a = redis.sparse_bitmap("a")
    b = redis.sparse_bitmap("b")
    result = redis.sparse_bitmap("result")

    b[0] = true; b[2] = true; b[7] = true # 10100001
    a[0] = true; a[1] = true; a[7] = true # 11000001

    c = a & b

    result << c

or just:

    result << (a & b)

You can specify the chunk size (in bytes).

Use the size consistently. Note that it cannot be re-adjusted for data already saved to Redis:

    x = redis.sparse_bitmap("x", 1024 * 1024) # 1 MB per chunk.
    x[0] = true
    x[1000] = true

**Important:** Do not mix sparse bitmaps with regular ones and never mix sparse bitmaps with different chunk sizes in the same expressions.

### Rationale

If you want to store a lot of huge but sparse bitsets, with not many bits set, using regular Redis bitmaps doesn't work very well. It wastes a lot of space. In analytics, it's a reasonable requirement, to be able to store data about several million users. A bitmap for 10 million users weights over 1MB! Imagine storing hourly statistics and using up memory at a rate of 720MB per month. 

For, say, 100 million users it becomes outright prohibitive!

But even with a fairly popular websites, I dare say, you don't often have one million users per hour :) This means that the majority of those bits is never sets and a lot of space goes wasted.

Enter sparse bitmaps. They divide each bitmap into chunks thus minimizing memory use (chunks' size can be configured, see Configuration below). 

Creating and using sparse bitmaps is identical to using regular bitmaps:

    huge = redis.sparse_bitmap("huge_bitmap")
    huge[128_000_000] = true

The only difference in the above example is that it will allocate two 32kb chunks as opposed to 1MB that would be allocated if we used a regular bitmap (Redis#bitmap). In addition, setting the bit is nearly instantaneous.

Compare:

    puts Benchmark.measure {
      sparse = redis.sparse_bitmap("huge_sparse_bitmap")
      sparse[500_000_000] = true
    }

which on my machine this generates:

    0.000000   0.000000   0.000000 (  0.000366)

It uses just 23kb memory as opposed to 120MB (megabytes!) to store the bit using a regular Redis bitmap:

      regular = redis.bitmap("huge_regular_bitmap")
      regular[500_000_000] = true

## Configuration

Here's how to configure the gem:

    Redis::Bitops.configure do |config|
      config.default_bytes_per_chunk = 8096 # Eight kilobytes.
      config.transaction_level = :bitmap # allowed values: :bitmap or :none.
    end

# Implementation & efficiency

## Optimization phase

Prior to evaluation, the expression is optimized by combining operators into single BITOP commands and reusing temporary keys (required to store intermediate results) as much as possible.

This silly example:

    result << (a & b & c | a | b)

translates into simply:

    BITOP AND result a b c
    BITOP OR result result a b

and doesn't create any temporary keys at all!

## Materialization phase

At this point, the calculations are carried out and the result is saved under the destination key. Note that, for sparse bitmaps, multiple keys may be created.


## Transaction levels

TBD


## Contributing/feedback

Please send in your suggestions to [gyamtso@gmail.com](mailto:gyamtso@gmail.com). Pull requests, issues, comments are more than welcome.
