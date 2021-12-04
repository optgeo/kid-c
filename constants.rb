SKIP = true
GENERATION = 'c'

LIST_PATH = 'all.txt'
#TASKS = %w{m321-1}
#TASKS = %w{m343 m349 m358}
TASKS = %w{m321-1 m321-2 m330-2 m343-1 m343-2 m349-1 m349-2 m358-1 m358-2}
#TASKS = %w{m330-1 m330-2 m349-1 m343-1 m358-1 m358-2 m358-3 m330-3 m343-2 m321-1 m321-2 m349-1 m349-2 m343-3 m349-3 m330-4}
#TASKS = %w{m321-1 m321-2 m330-1 m330-2 m343-1 m343-2 m349-1 m349-2 m358-1 m358-2}

TMP_DIR = '/tmp'
DEPLOY_TMP_DIR = 'tmp'
LOT_DIR = 'lot'
MBTILES_PATH = "#{DEPLOY_TMP_DIR}/tiles.mbtiles"
GDAL_DATA = '/usr/share/gdal'
PAGE_SIZE = 100

BASE_URL = 'https://x.optgeo.org/kid-c/zxy'
LNG = 138.779256
LAT = 35.158042
MAPLIBRE_VERSION = '1.15.2'

Z_ONE_METER = 19
BASE = 2

MAXZOOM = 19 #18 #19 #20
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

$taskname = nil
def taskname
  unless $taskname
    n = `ps aux | grep rake | wc -l`.to_i - 2
    $taskname = "#{hostname}-#{n}"
  end
  $taskname
end

def pomocode
  "[#{GENERATION}:#{Time.now.to_i / 1800}@#{taskname}]"
end

require 'digest/md5'

def hostmatch(basename)
  n = Digest::MD5.hexdigest(basename)[0..3].to_i(16)
  n % HOSTS.size == HOSTS.index(hostname)
end

def taskmatch(url)
  n = Digest::MD5.hexdigest(url)[0..3].to_i(16)
  n % TASKS.size == TASKS.index(taskname)
end
