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

  const inputs = document.getElementById('menu').getElementsByTagName('input');
  for (const input of inputs) {
    input.onclick = (layer) => {
      map.setStyle(layer.target.id)
    }
  }
}
init()

let map
const showMap = async (texts) => {
  map = new maplibregl.Map({
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
    map.on('click', 'voxel', e => {
      let u = new SpeechSynthesisUtterance()
      u.lang = 'en-GB'
      u.text = 'a voxel of ' + e.features[0].properties.spacing + 'meters.'
      if (voice) u.voice = voice
      speechSynthesis.cancel()
      speechSynthesis.speak(u)
    })
    map.on('click', 'grid', e => {
      let u = new SpeechSynthesisUtterance()
      u.lang = 'ja-JP'
      u.text = e.features[0].properties.MESH_NO
      //speechSynthesis.cancel()
      //speechSynthesis.speak(u)
    })
    map.on('moveend', e => {
      let fs = map.queryRenderedFeatures(
	[window.innerWidth / 2, window.innerHeight / 2], 
        { layers : ['voxel'] }
      )
      if (fs.length == 0) return
      let height = fs[0].properties.h 
      console.log(height)
    })
  })
}

window.onload = () => {
  showMap()
}
