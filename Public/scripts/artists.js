function parseArtistForm(form, callback) {
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  
  if (name.trim() == "")
    callback({"error": "Artist must have a name"})
  
  var shortDescriptionInput = document.getElementById("short-description-input")
  var shortDescription = shortDescriptionInput.value
  
  var descriptionInput = document.getElementById("description-input")
  var description = descriptionInput.value
  
  var spotifyInput = document.getElementById("spotify-input")
  var spotify = spotifyInput.value
    
  var appleMusicInput = document.getElementById("appleMusic-input")
  var appleMusic = appleMusicInput.value

  var googlePlayInput = document.getElementById("googlePlay-input")
  var googlePlay = googlePlayInput.value
  
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
  json["spotify"] = spotify
  json["appleMusic"] = appleMusic
  json["googlePlay"] = googlePlay
  json["instagram"] = instagram
  json["facebook"] = facebook
  json["website"] = website
  
  // Upload images
  
  var images = []
  var imageUploadStates = {}
  var imageInputs = document.getElementsByClassName("image-preview-wrapper")
  for (let input of imageInputs) {
    var imageInputJson = {}

    var creditTextInput = input.querySelector('.image-credit-text-input')
    imageInputJson["creditText"] = creditTextInput.value

    var creditLinkInput = input.querySelector('.image-credit-link-input')
    imageInputJson["creditLink"] = creditLinkInput.value
    
    var indexInput = input.querySelector('.image-index-input')
    imageInputJson["index"] = indexInput.value
    
    var idInput = input.querySelector('.image-id')
    if (idInput != null) {
      imageInputJson["id"] = idInput.value
      images.push(imageInputJson)
      continue
    }

    var fileInput = input.querySelector('.image-file-input')
    
    if (fileInput.files[0] === undefined)
      continue
    
    var reader = new FileReader()
    reader.onload = function(e) {
      var data = e.target.result
      imageInputJson["image"] = data
      imageUploadStates[fileInput.files[0].name] = true
      
      var imagesUploaded = true
      for (var key in imageUploadStates) {
        if (imageUploadStates.hasOwnProperty(key)) {
          var state = imageUploadStates[key]
          imagesUploaded = imagesUploaded && state
        }
      }
      if (imagesUploaded)
        callback(json)
    }
    
    imageUploadStates[fileInput.files[0].name] = false
    reader.readAsDataURL(fileInput.files[0])

    images.push(imageInputJson)
  }
  
  if (images.length == 0)
    callback({"error": "Artist must have at least one image"})
  
  json["images"] = images

  var allImagesAreUpdates = true
  for (let image of images) {
    allImagesAreUpdates = allImagesAreUpdates && image["id"] != null
  }
  if (allImagesAreUpdates)
    callback(json)
}

function submitArtist(e) {
  var createButton = document.getElementsByClassName('form-create-button')[0]
  createButton.disabled = true
  
  var form = e.parentElement
  parseArtistForm(form, function(json) {
    var error = document.getElementById('error');
    if (json['error']) {
      error.innerHTML = 'Error: ' + json['error']
      error.style.display = 'block'
      createButton.disabled = false
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
  })
}

function updateArtist(e) {
  var updateButton = document.getElementsByClassName('form-create-button')[0]
  var deleteButton = document.getElementsByClassName('delete-button')[0]
  updateButton.disabled = true
  deleteButton.disabled = true
  
  var form = e.parentElement
  parseArtistForm(form, function (json) {
    var error = document.getElementById('error');
    if (json['error']) {
      error.innerHTML = 'Error: ' + json['error']
      error.style.display = 'block'
      updateButton.disabled = false
      deleteButton.disabled = false
      return
    } else {
      error.style.display = 'none'
    }
    
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
  })
}

function addImageToArtist(e) {
  var parent = e.parentElement.parentElement
  var imagesDisplayRow = parent.querySelector('.images-row')

  var div = document.createElement("div")
  div.setAttribute('class', 'additional-field-input-wrapper')

  var previewWrapper = document.createElement('div')
  previewWrapper.setAttribute('class', 'image-preview-wrapper')

  var imagePreview = document.createElement('img')
  imagePreview.setAttribute('class', 'image')

  var creditsInputText = document.createElement('input')
  creditsInputText.setAttribute('class', 'image-credit-text-input')
  creditsInputText.setAttribute('placeholder', 'Image Credit Text')

  var creditsInputLink = document.createElement('input')
  creditsInputLink.setAttribute('class', 'image-credit-link-input')
  creditsInputLink.setAttribute('placeholder', 'Image Credit URL')
  
  var indexInputWrapper = document.createElement('div')
  
  var indexInputLabel = document.createElement('span')
  indexInputLabel.setAttribute('class', 'label')
  indexInputLabel.setAttribute('innerHTML', 'Index:')
  
  var indexInput = document.createElement('input')
  indexInput.setAttribute('class', 'image-index-input')
  indexInput.setAttribute('type', 'number')
  indexInput.setAttribute('value', 0)

  var buttonsWrapper = document.createElement('div')
  buttonsWrapper.setAttribute('class', 'buttons-wrapper')

  var browse = document.createElement('input')
  browse.setAttribute('class', 'image-file-input')
  browse.setAttribute('type', 'file')

  var deleteButton = document.createElement('input')
  deleteButton.setAttribute('class', 'delete-input-button')
  deleteButton.setAttribute('type', 'button')
  deleteButton.setAttribute('value', '-')
  deleteButton.setAttribute('onclick', 'deleteObjectInSelection(this.parentElement.parentElement)')

  buttonsWrapper.appendChild(browse)
  buttonsWrapper.appendChild(deleteButton)
  
  indexInputWrapper.appendChild(indexInputLabel)
  indexInputWrapper.appendChild(indexInput)

  previewWrapper.appendChild(imagePreview)
  previewWrapper.appendChild(creditsInputText)
  previewWrapper.appendChild(creditsInputLink)
  previewWrapper.appendChild(indexInputWrapper)
  previewWrapper.appendChild(buttonsWrapper)

  div.appendChild(previewWrapper)
  
  imagesDisplayRow.appendChild(div)
}
