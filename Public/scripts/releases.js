function parseReleaseForm(form, callback) {
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  if (name.trim() == "") {
    callback({
      'error': 'Release must have a name'
    })
    return
  }
  
  var date = form.date.value
  if (date == "") {
    callback({
      "error": "Release must have a release date"
    })
    return
  }
  
  var descriptionInput = document.getElementById("description-input")
  var description = descriptionInput.value
  
  var spotifyInput = document.getElementById("spotify-input")
  var spotify = spotifyInput.value
    
  var appleMusicInput = document.getElementById("appleMusic-input")
  var appleMusic = appleMusicInput.value

  var googlePlayInput = document.getElementById("googlePlay-input")
  var googlePlay = googlePlayInput.value
  
  var json = {}
  json["name"] = name
  json["date"] = date
  json["description"] = description
  json["spotify"] = spotify
  json["appleMusic"] = appleMusic
  json["googlePlay"] = googlePlay
  
  var artists = []
  var artistInputs = document.getElementsByClassName("artists-select")
  for (let input of artistInputs)
    artists.push(input.value)
  if (artists.length == 0) {
    callback({
      "error": "Release must have an artist"
    })
    return
  }

  json["artists"] = artists
  
  /* Parse image */
  
  var imageInputJson = {}
  var imageInput = document.getElementsByClassName("image-preview-wrapper")[0]
  var fileInput = imageInput.querySelector('.image-file-input')
  var reader = new FileReader()
  reader.onload = function(e) {
    var data = e.target.result
    imageInputJson["image"] = data
    callback(json)
    return
  }
  
  var idInput = imageInput.querySelector('.image-id')
  if (idInput != null) {
    if (fileInput.files[0] !== undefined) {
      reader.readAsDataURL(fileInput.files[0])
    } else {
      imageInputJson["id"] = idInput.value
      callback(json)
      return
    }
  } else {
    if (fileInput.files[0] === undefined) {
      callback({
        'error': 'Release must have an image'
      })
      return
    }
    reader.readAsDataURL(fileInput.files[0])
  }
  
  json["image"] = imageInputJson
}

function submitRelease(e) {
  var createButton = document.getElementsByClassName('form-create-button')[0]
  createButton.disabled = true
  
  var form = e.parentElement
  var json = parseReleaseForm(form, function (json) {
    var error = document.getElementById('error')
    if (json["error"]) {
      error.innerHTML = 'Error: ' + json['error']
      error.style.display = 'block'
      createButton.disabled = false
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
  })
}

function updateRelease(e) {
  var updateButton = document.getElementsByClassName('form-create-button')[0]
  var deleteButton = document.getElementsByClassName('delete-button')[0]
  updateButton.disabled = true
  deleteButton.disabled = true
  
  var form = e.parentElement
  var json = parseReleaseForm(form, function (json) {
    var error = document.getElementById('error')
    if (json["error"]) {
      error.innerHTML = 'Error: ' + json['error']
      error.style.display = 'block'
      updateButton.disabled = false
      deleteButton.disabled = false
      return
    } else {
      error.style.display = 'none'
    }
                              
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
  })
}

function populateArtistSelector(e) {
  var value = e.textContext
  
  var httpreq = new XMLHttpRequest()
  httpreq.open("GET", "/api/artist", true)
  httpreq.onreadystatechange = function () {
    if (httpreq.readyState == 4 && httpreq.status == 200) {
      var artists = JSON.parse(httpreq.responseText)
      
      var div = document.createElement("div")
      div.setAttribute("class", "additional-field-input-wrapper")
      
      var select = document.createElement("select")
      select.setAttribute("name", "artists")
      select.setAttribute("class", "form-control artists-select")
      
      artists.forEach(function (artist, index) {
        select.options[select.options.length] = new Option(artist.name, artist.name)
      })
      
      if (value != null) {
        select.value = value
      }

      var input = document.createElement("input")
      input.setAttribute("class", "delete-input-button")
      input.setAttribute("type", "button")
      input.setAttribute("value", "-")
      input.setAttribute("onclick", "deleteObjectInSelection(this)")
      
      div.appendChild(select)
      div.appendChild(input)
      
      e.appendChild(div)
    }
  }
  
  httpreq.send(null)
}
