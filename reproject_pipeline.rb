require './constants'
require 'yaml'
require 'json'

basename = ENV['BASENAME']
src_path = "#{TMP_DIR}/#{basename}.las"
dst_path = "#{TMP_DIR}/#{basename}-3857.las"

pipeline = <<-EOS
pipeline: 
  - 
    filename: #{src_path}
    type: readers.las
    spatialreference: "EPSG:6676"
  -
    type: filters.reprojection
    out_srs: "EPSG:3857"
  -
    type: writers.las
    filename: #{dst_path}
EOS

print JSON.dump(YAML.load(pipeline))
