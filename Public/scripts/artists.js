function toggleShowCreateArtist() {
  var form = document.getElementById("create-artist-form")
  form.style.display = form.style.display == "none" ? "block" : "none"
}

function parseArtistForm(form) {
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  
  var descriptionInput = document.getElementById("description-input")
  var description = descriptionInput.value
  
  var imageInput = document.getElementById("image-input")
  var image = imageInput.value
  
  var spotifyInput = document.getElementById("spotify-input")
  var spotify = spotifyInput.value
  
  var instagramInput = document.getElementById("instagram-input")
  var instagram = instagramInput.value
  
  var facebookInput = document.getElementById("facebook-input")
  var facebook = facebookInput.value
  
  var websiteInput = document.getElementById("website-input")
  var website = websiteInput.value
  
  var json = {}
  json["name"] = name
  json["description"] = description
  json["image"] = image
  json["spotify"] = spotify
  json["instagram"] = instagram
  json["facebook"] = facebook
  json["website"] = website
  
  return json
}

function submitArtist(e) {
  var form = e.parentElement
  var json = parseArtistForm(form)
  
  if (json["error"])
    return
    
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