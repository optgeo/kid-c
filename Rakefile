require './constants'

desc 'build docs/style.json from style/style.yml using charites'
task :style do
  sh "charites build style/style.yml docs/style.json"
end

desc 'create a single tiles.mbtiles from zoom-wise parts'
task :join do
  files = (MINZOOM..MAXZOOM).map {|v| "#{DEPLOY_TMP_DIR}/deploy-#{v}.mbtiles"}
  sh <<-EOS
tile-join --force --output=#{MBTILES_PATH} --no-tile-size-limit \
#{files.join(' ')} ; \
rm -v #{DEPLOY_TMP_DIR}/deploy-*.mbtiles
  EOS
  notify "🎇#{MBTILES_PATH} is updated"
end

desc 'run vt-optimizer'
task :optimize do
  sh <<-EOS
node ~/vt-optimizer/index.js -m #{MBTILES_PATH}
  EOS
end

desc 'copy .pbf vector tiles from .mbtiles'
task :deploy do
  notify "🎆#{pomocode}deploy started"
  tmp_dir = "#{DEPLOY_TMP_DIR}/zxy"
  sh "mkdir #{tmp_dir}" unless File.exist?(tmp_dir)
  sh "mkdir docs/zxy" unless File.exist?('docs/zxy')
  MINZOOM.upto(MAXZOOM) {|z|
    mbtiles_path = "#{DEPLOY_TMP_DIR}/deploy-#{z}.mbtiles"
    files = Dir.glob("#{LOT_DIR}/*-#{z}.mbtiles")
    files.select! {|path| !File.exist?("#{path}-journal")}
    files.select! {|path| File.size(path) != 0}
    files.sort!
    n_pages = (files.size.to_f / PAGE_SIZE).ceil
    n_pages.times {|page|
      page_path = "#{DEPLOY_TMP_DIR}/deploy-#{z}-#{page}.mbtiles"
      fs = files.slice(page * PAGE_SIZE, PAGE_SIZE).select {|path|
        File.exists?(path) && File.size(path) != 0
      }.join(' ')
      sh <<-EOS
tile-join --force --output=#{page_path} \
--no-tile-size-limit \
#{fs}
      EOS
      # notify "🎆#{pomocode}#{page + 1} of #{n_pages} for #{z}" if z >= 17
    }
    sh <<-EOS
tile-join --force --output=#{mbtiles_path} \
--no-tile-size-limit \
#{DEPLOY_TMP_DIR}/deploy-#{z}-*.mbtiles ; \
rm -v #{DEPLOY_TMP_DIR}/deploy-#{z}-*.mbtiles
    EOS
    if z == 19 # because z=19 is too large
      sh <<-EOS
rm -r docs/zxy/#{z}
      EOS
    end
    sh <<-EOS
tile-join --force --output-to-directory=#{tmp_dir} \
--no-tile-size-limit --no-tile-compression \
#{mbtiles_path}
    EOS
    z.downto(z == MINZOOM ? MINCOPYZOOM : z) {|zc|
      sh "rm -r docs/zxy/#{zc}" if File.exist?("docs/zxy/#{zc}")
      sh <<-EOS
mv #{tmp_dir}/#{zc} docs/zxy
      EOS
    }
    notify "🎆#{pomocode}deployed #{z}"
  }
  notify "🎆#{pomocode}deploy finished"
end

desc 'deploy .pbf files continuously - useful for a long production'
task :continuous_deploy do
  20.times {|i|
    sh "rake deploy"
    sh "rake join"
    sh "sleep 3600"
  }
end

task :health_check do
  Dir.glob("#{LOT_DIR}/*.mbtiles") {|path|
    next if File.exist?("#{path}-journal")
    count = `sqlite3 #{path} 'select count(*) from tiles;'`.strip.to_i
    next unless count == 0 
    print "https://gic-shizuoka.s3-ap-northeast-1.amazonaws.com/2020/LP/00/" + 
      "#{path.split('/')[1].split('-')[0]}.zip\n"
  }
end

task :clean do
  [TMP_DIR, DEPLOY_TMP_DIR].each {|tmp_dir|
    sh "rm -r #{tmp_dir}/zxy" if File.exist?("#{tmp_dir}/zxy")
    sh "rm #{tmp_dir}/*" unless Dir.glob("#{tmp_dir}/*").size == 0
  }
  sh "rm #{LOT_DIR}/*" unless Dir.glob("#{LOT_DIR}/*").size == 0
end

task :fix do
  sh "ruby fix.rb > fix.txt"
end

task :default do
  task_name = File.basename(LIST_PATH, '.txt')
  list_size = `wc -l #{LIST_PATH}`.to_i
  notify "🐧#{pomocode} #{task_name} (#{list_size}) started"
  count = 0
  File.foreach(LIST_PATH) {|url|
    count += 1
    skip_all = true
    url = url.strip
    basename = File.basename(url.split('/')[-1], '.zip')
    next unless taskmatch(url)
    tmp_path = "#{TMP_DIR}/#{basename}"
    cmd = <<-EOS
curl -o #{tmp_path}.zip #{url} ; \
unar -f -o #{TMP_DIR} #{tmp_path}.zip 1>&2 ; \
BASENAME=#{basename} ruby reproject_pipeline.rb | \
pdal pipeline --stdin ;
    EOS
    MAXZOOM.downto(MINZOOM) {|z|
      dst_path = "#{LOT_DIR}/#{basename}-#{z}.mbtiles"
      work_path = "#{TMP_DIR}/#{basename}-#{z}.mbtiles"
      if SKIP && File.exist?(dst_path) && 
          !File.exist?("#{dst_path}-journal") ## && File.size(dst_path) > 20000
        tile_count = `sqlite3 #{dst_path} 'select count(*) from tiles'`.strip.to_i
        if tile_count == 0
          $stderr.print "deleted unhealthy #{dst_path}.\n"
          sh "rm #{dst_path}"
          skip_all = false
        else
          $stderr.print "skip #{dst_path} because it has #{tile_count} tiles.\n"
          next
        end
      else
        skip_all = false
      end
      cmd += <<-EOS
Z=#{z} BASENAME=#{basename} ruby resample_text_pipeline.rb | \
pdal pipeline --stdin | \
Z=#{z} ruby togeojson.rb | \
tippecanoe \
--maximum-zoom=#{MAXZOOM} \
--minimum-zoom=#{MINCOPYZOOM} \
--projection=EPSG:3857 \
--force \
--output=#{work_path} \
--no-tile-size-limit \
--no-feature-limit ; \
mv #{work_path} #{dst_path} ;
      EOS
    }
    cmd += <<-EOS
rm -v #{TMP_DIR}/#{basename}*
    EOS
    sh cmd unless skip_all
    notify"#{pomocode} #{basename} (#{task_name}, #{count} of #{list_size})" unless skip_all
  }
  notify "✨#{pomocode} #{task_name} (#{list_size}) finished"
end

task :maplibre do
  %w{js js.map css}.each {|ext|
    sh <<-EOS
curl -o docs/maplibre-gl.#{ext} -L https://unpkg.com/maplibre-gl@#{MAPLIBRE_VERSION}/dist/maplibre-gl.#{ext}
    EOS
  } 
end

