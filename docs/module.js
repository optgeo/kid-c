const style = href => {
  const e = document.createElement('link')
  e.href = href
  e.rel = 'stylesheet'
  document.head.appendChild(e)
}

const script = src => {
  const e = document.createElement('script')
  e.src = src
  document.head.appendChild(e)
}

const init = () => {
  style('style.css')
  style('maplibre-gl.css')
  script('maplibre-gl.js')
  const map = document.createElement('div')
  map.id = 'map'
  document.body.appendChild(map)
}
init()

const showMap = async (texts) => {
  const map = new maplibregl.Map({
    container: 'map',
    hash: true,
    style: 'style.json',
    maxZoom: 18.6
  })
  map.addControl(new maplibregl.NavigationControl())
  map.addControl(new maplibregl.ScaleControl({
    maxWidth: 200, unit: 'metric'
  }))

  let voice = null
  for(let v of speechSynthesis.getVoices()) {
    console.log(v.name)
    if ([
      'Daniel',
      'Google UK English Male',
      'Microsoft Libby Online (Natural) - English (United Kingdom)'
    ].includes(v.name)) voice = v
  }

  map.on('load', () => {
    map.on('click', 'voxel', (e) => {
      let u = new SpeechSynthesisUtterance()
      u.lang = 'en-GB'
      u.text = 'a voxel of ' + e.features[0].properties.spacing + 'meters.'
      if (voice) u.voice = voice
      speechSynthesis.cancel()
      speechSynthesis.speak(u)
    })

  })
}

const main = async () => {
  if (typeof maplibregl == 'undefined') {
    window.onload = () => {
      showMap()
    }
  } else {
    showMap()
  }
}
main()
