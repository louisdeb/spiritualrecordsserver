function parseReleaseForm(form) {
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  if (name.trim() == "") {
    return {
      'error': 'Release must have a name'
    }
  }
  
  // Extend here for multiple artists per release
  var artistInputs = document.getElementsByClassName("artists-select")
  var artist = artistInputs[0].value
  if (artist.trim() == "") {
    return {
      "error": "Release must have an artist"
    }
  }
  
  var date = form.date.value
  if (date == "") {
    return {
      "error": "Release must have a release date"
    }
  }
  
  var descriptionInput = document.getElementById("description-input")
  var description = descriptionInput.value

  var imageInput = document.getElementById("image-input")
  var image = imageInput.value
  if (image.trim() == "") {
    return {
      "error": "Release must have an image"
    }
  }
  
  var spotifyInput = document.getElementById("spotify-input")
  var spotify = spotifyInput.value
    
  var appleMusicInput = document.getElementById("appleMusic-input")
  var appleMusic = appleMusicInput.value
  
  var json = {}
  json["name"] = name
  json["date"] = date
  json["description"] = description
  json["imageURL"] = image
  json["spotify"] = spotify
  json["appleMusic"] = appleMusic

  json["artist"] = artist
  
  return json
}

function submitRelease(e) {
  var form = e.parentElement
  var json = parseReleaseForm(form)
  
  var error = document.getElementById('error')
  if (json["error"]) {
    error.innerHTML = 'Error: ' + json['error']
    error.style.display = 'block'
    return
  } else {
    error.style.display = 'none'
  }
    
  console.log("Submitting release creation with JSON:")
  console.log(json)
  
  var formreq = new XMLHttpRequest()
  formreq.open(form.method, form.action, true)
  formreq.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  formreq.onreadystatechange = function() {
    console.log("... Submitted. Reloading page")
    location.reload(true)
  }
  
  formreq.send(JSON.stringify(json))
}

function updateRelease(e) {
  var form = e.parentElement
  var json = parseReleaseForm(form)
  
  var idInput = document.getElementById("release-id")
  var id = idInput.value
  json["id"] = id
  
  console.log("Updating release with JSON:")
  console.log(json)
  
  var formreq = new XMLHttpRequest()
  formreq.open(form.method, form.action, true)
  formreq.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  formreq.onreadystatechange = function () {
    location.replace("/app/releases")
  }
  
  formreq.send(JSON.stringify(json))
}

function deleteRelease(id) {
  let delreq = new XMLHttpRequest()
  delreq.open("POST", "/api/release/" + id + "/delete", true)
  delreq.onreadystatechange = function () {
    location.replace("/app/releases")
  }
  
  delreq.send()
}

function populateArtistSelector(e) {
  var value = e.textContext
  
  var httpreq = new XMLHttpRequest()
  httpreq.open("GET", "/api/artist", true)
  httpreq.onreadystatechange = function () {
    if (httpreq.readyState == 4 && httpreq.status == 200) {
      var artistResponses = JSON.parse(httpreq.responseText)
      
      var div = document.createElement("div")
      div.setAttribute("class", "additional-field-input-wrapper")
      
      var select = document.createElement("select")
      select.setAttribute("name", "artists")
      select.setAttribute("class", "form-control artists-select")
      
      artistResponses.forEach(function (artistResponse, index) {
        var artist = artistResponse.artist
        select.options[select.options.length] = new Option(artist.name, artist.name)
      })
      
      if (value != null) {
        select.value = value
      }
      
      div.appendChild(select)
      
      e.appendChild(div)
    }
  }
  
  httpreq.send(null)
}
