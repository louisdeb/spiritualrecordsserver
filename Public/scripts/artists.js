function parseArtistForm(form) {
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  if (name.trim() == "") {
    return {
      "error": "Artist must have a name"
    }
  }
  
  var shortDescriptionInput = document.getElementById("short-description-input")
  var shortDescription = shortDescriptionInput.value
  
  var descriptionInput = document.getElementById("description-input")
  var description = descriptionInput.value

  var images = []
  var imageInputs = document.getElementsByClassName("image-input")
  for (let input of imageInputs)
    images.push(input.value)
  if (images.length == 0) {
    return {
      "error": "Artist must have at least one image"
    }
  }
  
  var spotifyInput = document.getElementById("spotify-input")
  var spotify = spotifyInput.value
    
  var appleMusicInput = document.getElementById("appleMusic-input")
  var appleMusic = appleMusicInput.value
  
  var instagramInput = document.getElementById("instagram-input")
  var instagram = instagramInput.value
  
  var facebookInput = document.getElementById("facebook-input")
  var facebook = facebookInput.value
  
  var websiteInput = document.getElementById("website-input")
  var website = websiteInput.value
  
  var json = {}
  json["name"] = name
  json["shortDescription"] = shortDescription
  json["description"] = description
  json["imageURLs"] = images
  json["spotify"] = spotify
  json["appleMusic"] = appleMusic
  json["instagram"] = instagram
  json["facebook"] = facebook
  json["website"] = website
  
  return json
}

function submitArtist(e) {
  var form = e.parentElement
  var json = parseArtistForm(form)
  
  var error = document.getElementById('error');
  if (json['error']) {
    error.innerHTML = 'Error: ' + json['error']
    error.style.display = 'block'
    return 
  } else {
    error.style.display = 'none'
  }
  
  console.log("Submitting artist creation with JSON:")
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

function updateArtist(e) {
  var form = e.parentElement
  var json = parseArtistForm(form)
  
  var idInput = document.getElementById("artist-id")
  var id = idInput.value
  json["id"] = id
  
  console.log("Updating artist with JSON:")
  console.log(json)
  
  var formreq = new XMLHttpRequest()
  formreq.open(form.method, form.action, true)
  formreq.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  formreq.onreadystatechange = function () {
    location.replace("/app/artists")
  }
  
  formreq.send(JSON.stringify(json))
}

function addImageToArtist(e) {
  var parent = e.parentElement
  
  var div = document.createElement("div")
  div.setAttribute('class', 'additional-field-input-wrapper')
  var html = "<input class='image-input' type='text'><input class='delete-input-button' type='button' value='-' onclick='deleteObjectInSelection(this)'>"
  div.innerHTML = html
  
  parent.appendChild(div)
}
