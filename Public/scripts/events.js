function toggleShowCreateEvent() {
  var form = document.getElementById("create-event-form")
  form.style.display = form.style.display == "none" ? "block" : "none"
}

function addArtistToSelect(e, value) {
  var parent = e.parentElement
  
  var httpreq = new XMLHttpRequest()
  httpreq.open("GET", "/api/artist", true)
  httpreq.onreadystatechange = function () {
    if (httpreq.readyState == 4 && httpreq.status == 200) {
      var artistResponses = JSON.parse(httpreq.responseText)
      
      var div = document.createElement("div")
      div.setAttribute("class", "artist-select")
      
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
      
      var input = document.createElement("input")
      input.setAttribute("type", "button")
      input.setAttribute("value", "-")
      input.setAttribute("onclick", "deleteArtistInSelection(this)")
      
      div.appendChild(select)
      div.appendChild(input)
      
      parent.appendChild(div)
    }
  }
  
  httpreq.send(null)
}

function deleteArtistInSelection(e) {
  var parent = e.parentElement
  parent.parentElement.removeChild(parent)
}

function addUnsignedArtist(e) {
  var parent = e.parentElement
  
  var div = document.createElement("div")
  var html = "<input class='unsigned-artist-input' type='text'><input type='button' value='-' onclick='deleteArtistInSelection(this)'>"
  div.innerHTML = html
  
  parent.appendChild(div)
}

function parseEventForm(form) {
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  
  var date = form.date.value
  if (date == "") {
    var dateWarning = document.getElementById("dateWarning")
    dateWarning.style.display = "block"
    return {"error": true}
  }
  
  var descriptionInput = document.getElementById("description-input")
  var description = descriptionInput.value
  
  var artists = []
  var artistSelectors = document.getElementsByClassName("artists-select")
  for (let selector of artistSelectors)
    artists.push(selector.value)
    
  var unsignedArtists = []
  var unsignedArtistSelectors = document.getElementsByClassName("unsigned-artist-input")
  for (let selector of unsignedArtistSelectors)
    unsignedArtists.push(selector.value)
  
  var priceInput = document.getElementById("price-input")
  var price = priceInput.value
  
  var json = {}
  json["name"] = name
  json["date"] = date
  json["description"] = description
  json["artists"] = artists
  json["unsignedArtists"] = unsignedArtists
  json["price"] = price
  
  return json
}

function submitEvent(e) {
  var form = e.parentElement
  var json = parseEventForm(form)
  
  if (json["error"])
    return
  
  console.log("Submitting event creation with JSON:")
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

function updateEvent(e) {
  var form = e.parentElement
  var json = parseEventForm(form)
  
  var idInput = document.getElementById("event-id")
  var id = idInput.value
  json["id"] = id
  
  console.log("Updating event with JSON:")
  console.log(json)
  
  var formreq = new XMLHttpRequest()
  formreq.open(form.method, form.action, true)
  formreq.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  formreq.onreadystatechange = function () {
    location.replace("/app/events")
  }
  
  formreq.send(JSON.stringify(json))
}

function populateArtistSelectors(selectionElems) {
  if (selectionElems.length == 0) { return }

  var selectedArtists = []
  for (let selection of selectionElems) {
    selectedArtists.push(selection.textContent)
  }
  
  for (let selectedArtist of selectedArtists) {
    addArtistToSelect(selectionElems[0].parentElement, selectedArtist)
  }
}

function deleteArtist(id) {
  let delreq = new XMLHttpRequest()
  delreq.open("POST", "/api/artist/" + id + "/delete", true)
  delreq.onreadystatechange = function () {
    location.replace("/app/artists")
  }
  
  delreq.send()
}

function deleteEvent(id) {
  let delreq = new XMLHttpRequest()
  delreq.open("POST", "/api/event/" + id + "/delete", true)
  delreq.onreadystatechange = function () {
    location.replace("/app/events")
  }
  
  delreq.send()
}
