require './constants'

task :style do
  sh "charites build style/style.yml docs/style.json"
end

task :join do
  files = (MINZOOM..MAXZOOM).map {|v| "#{DEPLOY_TMP_DIR}/deploy-#{v}.mbtiles"}
  sh <<-EOS
tile-join --force --output=#{MBTILES_PATH} --no-tile-size-limit \
#{files.join(' ')} ; \
rm -v #{DEPLOY_TMP_DIR}/deploy-*.mbtiles
  EOS
  notify "🎇#{MBTILES_PATH} is updated"
end

task :optimize do
  sh <<-EOS
node ~/vt-optimizer/index.js -m #{MBTILES_PATH}
  EOS
end

task :deploy do
  notify "🎆#{pomocode}deploy started"
  tmp_dir = "#{DEPLOY_TMP_DIR}/zxy"
  sh "mkdir #{tmp_dir}" unless File.exist?(tmp_dir)
  sh "mkdir docs/zxy" unless File.exist?('docs/zxy')
  MINZOOM.upto(MAXZOOM) {|z|
    mbtiles_path = "#{DEPLOY_TMP_DIR}/deploy-#{z}.mbtiles"
    files = Dir.glob("#{LOT_DIR}/*-#{z}.mbtiles")
    files.select! {|path| !File.exist?("#{path}-journal")}
    files.sort!
    n_pages = (files.size.to_f / PAGE_SIZE).ceil
    n_pages.times {|page|
      page_path = "#{DEPLOY_TMP_DIR}/deploy-#{z}-#{page}.mbtiles"
      sh <<-EOS
tile-join --force --output=#{page_path} \
--no-tile-size-limit \
#{files.slice(page * PAGE_SIZE, PAGE_SIZE).join(' ')}
      EOS
      # notify "🎆#{pomocode}#{page + 1} of #{n_pages} for #{z}" if z >= 17
    }
    sh <<-EOS
tile-join --force --output=#{mbtiles_path} \
--no-tile-size-limit \
#{DEPLOY_TMP_DIR}/deploy-#{z}-*.mbtiles
    EOS
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
    next unless hostmatch(basename)
    tmp_path = "#{TMP_DIR}/#{basename}"
    cmd = <<-EOS
curl -o #{tmp_path}.zip #{url} ; \
unar -f -o #{TMP_DIR} #{tmp_path}.zip 1>&2 ; \
GDAL_DATA=#{GDAL_DATA} BASENAME=#{basename} ruby reproject_pipeline.rb | \
pdal pipeline --stdin ;
    EOS
    cmd.chomp!
    MAXZOOM.downto(MINZOOM) {|z|
      dst_path = "#{LOT_DIR}/#{basename}-#{z}.mbtiles"
      work_path = "#{TMP_DIR}/#{basename}-#{z}.mbtiles"
      if SKIP && File.exist?(dst_path) && 
          !File.exist?("#{dst_path}-journal") ## && File.size(dst_path) > 20000
        $stderr.print "skip #{dst_path} because it is there.\n"
        next
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
--no-feature-limit ;
      EOS
      cmd.chomp!
    }
    cmd += <<-EOS
mv #{work_path} #{dst_path}; \
rm -v #{TMP_DIR}/#{basename}*
    EOS
    cmd.chomp!
    sh cmd unless skip_all
    notify"#{pomocode} #{basename} (#{task_name}, #{count} of #{list_size})" unless skip_all
  }
  notify "✨#{pomocode} #{task_name} (#{list_size}) finished"
end
