SKIP = true
GENERATION = 'c'

LIST_PATH = 'nirayama.txt'
#HOSTS = %w{m321 m343 m354}
#HOSTS = %w{m321 m343}
HOSTS = %w{m343}

TMP_DIR = '/tmp'
LOT_DIR = 'lot'
MBTILES_PATH = "#{TMP_DIR}/tiles.mbtiles"
GDAL_DATA = '/usr/share/gdal'
PAGE_SIZE = 50

BASE_URL = 'https://x.optgeo.org/kid-c/zxy'
LNG = 138.779256
LAT = 35.158042

Z_ONE_METER = 19
BASE = 2

MAXZOOM = 18 #19
MINZOOM = 10
MINCOPYZOOM = 10

LAYER = 'voxel'

SLACK = true
$notifier = nil
if SLACK
  require 'slack-notifier'
  $notifier = Slack::Notifier.new ENV['WEBHOOK_URL']
end

def notify(msg)
  $stderr.print msg, "\n"
  $notifier.ping(msg)
end

def hostname
  `hostname`.strip
end

def pomocode
  "[#{GENERATION}:#{Time.now.to_i / 1800}@#{hostname}]"
end

def hostmatch(basename)
  n = basename[-4..-1].to_i
  n % HOSTS.size == HOSTS.index(hostname)
end
