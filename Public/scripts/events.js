function addArtistToSelect(e, value) {
  var parent = e.parentElement
  
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
      
      parent.appendChild(div)
    }
  }
  
  httpreq.send(null)
}

function addUnsignedArtist(e) {
  var parent = e.parentElement
  
  var div = document.createElement("div")
  div.setAttribute("class", "additional-field-input-wrapper")

  var unsignedArtistInput = document.createElement("input")
  unsignedArtistInput.setAttribute("class", "unsigned-artist-input")
  unsignedArtistInput.setAttribute("type", "text")
  unsignedArtistInput.setAttribute("placeholder", "Name")

  var unsignedArtistLinkInput = document.createElement("input")
  unsignedArtistLinkInput.setAttribute("class", "unsigned-artist-link-input")
  unsignedArtistLinkInput.setAttribute("type", "text")
  unsignedArtistLinkInput.setAttribute("placeholder", "Link")

  var deleteInputButton = document.createElement("input")
  deleteInputButton.setAttribute("class", "delete-input-button")
  deleteInputButton.setAttribute("type", "button")
  deleteInputButton.setAttribute("value", "-")
  deleteInputButton.setAttribute("onclick", "deleteObjectInSelection(this)")

  div.appendChild(unsignedArtistInput)
  div.appendChild(unsignedArtistLinkInput)
  div.appendChild(deleteInputButton)
  
  parent.appendChild(div)
}

function parseEventForm(form) {
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  
  var date = form.date.value
  if (date == "") {
    return {
      "error": "Event must have a date"
    }
  }
  
  var descriptionInput = document.getElementById("description-input")
  var description = descriptionInput.value
  
  var artists = []
  var artistSelectors = document.getElementsByClassName("artists-select")
  for (let selector of artistSelectors)
    artists.push(selector.value)
    
  var unsignedArtists = []
  var unsignedArtistSelectors = document.getElementsByClassName("unsigned-artist-input")
  for (let selector of unsignedArtistSelectors) {
    var unsignedArtistName = selector.value

    var linkInput = selector.parentElement.getElementsByClassName("unsigned-artist-link-input")[0]
    var unsignedArtistLink = linkInput.value

    unsignedArtists.push({
      "name": unsignedArtistName,
      "link": unsignedArtistLink,
    })
  }
  
  var priceInput = document.getElementById("price-input")
  var price = priceInput.value
  if (price.trim() == "")
    price = "Free"
  
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
  
  var error = document.getElementById('error')
  if (json["error"]) {
    error.innerHTML = 'Error: ' + json['error']
    error.style.display = 'block'
    return
  } else {
    error.style.display = 'none'
  }
  
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

function eventDateChanged(e) {
  var openMicCheckbox = document.getElementById("open-mic-checkbox");
  var openMicCheckboxLabel = document.getElementById("open-mic-checkbox-label");
  openMicCheckbox.style.display = e.valueAsDate.getDay() == 2 ? 'block' : 'none';
  openMicCheckboxLabel.style.display = e.valueAsDate.getDay() == 2 ? 'block' : 'none';
}

var prevName = "";
var prevDescription = "";
var prevPrice = "";

function openMicChecked(e) {
  var nameInput = document.getElementById("name-input");
  var descriptionInput = document.getElementById("description-input");
  var priceInput = document.getElementById("price-input");
  
  if (e.checked) {
    prevName = nameInput.value;
    prevDescription = descriptionInput.value;
    prevPrice = priceInput.value;
    
    nameInput.value = "Tuesday Open Mic";
    descriptionInput.value = "Bring your instruments and original music every Tuesday. Sign up from 6pm";
    priceInput.value = "";
  } else {
    nameInput.value = prevName;
    descriptionInput.value = prevDescription;
    priceInput.value = prevPrice;
  }
}
