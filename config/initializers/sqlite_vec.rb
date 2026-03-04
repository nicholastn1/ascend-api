# sqlite-vec is loaded lazily by VectorSearch module when needed,
# rather than on every connection, to avoid interfering with
# ActiveRecord's connection management and transactional fixtures.
#
# See app/models/concerns/vector_search.rb
