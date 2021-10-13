require './constants'
require 'yaml'
require 'json'

z = ENV['Z'].to_i
minzoom = (z == MINZOOM) ? MINCOPYZOOM : z
maxzoom = z
spacing = (BASE ** (Z_ONE_METER - z)).to_f
n = 0

first = true
while gets
  if first
    first = false
    next
  else
    n += 1
  end
  r = $_.strip.split(',')
  x = r[0].to_f - r[0].to_f % spacing
  y = r[1].to_f - r[1].to_f % spacing
  h = r[2].to_f - r[2].to_f % spacing
  h = h.to_i
  color = '#' + r[13..15].map{|v| sprintf('%01x', v.to_i / 4096)}.join
  g = <<-EOS
type: Polygon
coordinates: 
  -
    -
      - #{x}
      - #{y}
    -
      - #{x + spacing}
      - #{y}
    -
      - #{x + spacing}
      - #{y + spacing}
    -
      - #{x}
      - #{y + spacing}
    -
      - #{x}
      - #{y}
  EOS
  g = YAML.load(g)
  f = <<-EOS
type: Feature
properties: 
  color: '#{color}'
#  classification: #{r[8].to_i}
#  height: #{r[2].to_f}
  h: #{h}
  spacing: #{spacing}
tippecanoe:
  minzoom: #{minzoom}
  maxzoom: #{maxzoom}
  layer: #{LAYER}
  EOS
  f = YAML.load(f)
  f[:geometry] = g
  print JSON.dump(f), "\n"
end

