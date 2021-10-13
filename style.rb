require './constants'
require 'yaml'
require 'json'

print JSON.pretty_generate(YAML.load(
<<EOS
version: 8
center:
  - #{LNG}
  - #{LAT}
zoom: 17
layers:
  -
    id: background
    type: background
    paint:
      background-color: rgb(40, 40, 40)
  -
    id: voxel
    type: fill-extrusion
    source: voxel
    source-layer: voxel
    paint: 
      fill-extrusion-base: 
        - get
        - h
      fill-extrusion-color:
        - get
        - color
      fill-extrusion-height: 
        - '+'
        -
          - get
          - h
        - 
          - get
          - spacing
sources:
  voxel:
    type: vector
    attribution: "出典:静岡県ポイントクラウドデータベース"
    minzoom: #{MINCOPYZOOM}
    maxzoom: #{MAXZOOM}
    tiles:
      - #{BASE_URL}/{z}/{x}/{y}.pbf
EOS
))
