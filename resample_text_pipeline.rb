require './constants'
require 'yaml'
require 'json'

z = ENV['Z'].to_i
spacing = (BASE ** (Z_ONE_METER - z)).to_f
basename = ENV['BASENAME']
#src_path = "#{TMP_DIR}/#{basename}-#{z - 1}.las"
src_path = "#{TMP_DIR}/#{basename}-3857.las" #unless File.exist?(src_path)
dst_path = "#{TMP_DIR}/#{basename}-#{z}.las"
$stderr.print "#{spacing}m for #{dst_path} from #{src_path}\n"

pipeline = <<-EOS
pipeline: 
  - 
    filename: #{src_path}
    type: readers.las
  -
    type: filters.voxelcentroidnearestneighbor
    cell: #{spacing}
  -
    type: writers.text
    format: csv
    filename: STDOUT
EOS

print JSON.dump(YAML.load(pipeline))
