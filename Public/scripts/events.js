function toggleShowCreateEvent() {
  var form = document.getElementById("create-event-form")
  form.style.display = form.style.display == "none" ? "block" : "none"
}

function addArtistToSelect(e) {
  var parent = e.parentElement
  
  var httpreq = new XMLHttpRequest()
  httpreq.open("GET", "/api/artist", true)
  httpreq.onreadystatechange = function () {
    if (httpreq.readyState == 4 && httpreq.status == 200) {
      var artists = JSON.parse(httpreq.responseText)
      
      var div = document.createElement("div")
      var html = "<select id='artists' name='artists' class='form-control artists-select'>"
      artists.forEach(function (artist, index) {
        html += "<option value = '" + artist.name + "'>" + artist.name + "</option>"
      })
      html += "</select><input type='button' value='-' onclick='deleteArtistInSelection(this)'>"
      div.innerHTML = html
      div.setAttribute("class", "artist-select")
      
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

function submitEvent(e) {
  var form = e.parentElement
  
  var date = form.date.value
  if (date == "") {
    var dateWarning = document.getElementById("dateWarning")
    dateWarning.style.display = "block"
    return
  }
  
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  
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
  json["date"] = date
  json["name"] = name
  json["artists"] = artists
  json["unsignedArtists"] = unsignedArtists
  json["price"] = price
  
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
