function parseInterviewForm(form) {
  var nameInput = document.getElementById("name-input")
  var name = nameInput.value
  if (name.trim() == "") {
    return {
      'error': 'Interview must have a name'
    }
  }
  
  var artists = []
  var artistInputs = document.getElementsByClassName("artists-select")
  for (let input of artistInputs)
    artists.push(input.value)
  
  var date = form.date.value
  if (date == "") {
    return {
      "error": "Interview must have a date"
    }
  }
  
  var shortDescriptionInput = document.getElementById("short-description-input")
  var shortDescription = shortDescriptionInput.value
  
  var descriptionInput = document.getElementById("description-input")
  var description = descriptionInput.value
  
  var videoURLInput = document.getElementById("video-input")
  var videoURL = videoURLInput.value
  
  var json = {}
  json["name"] = name
  json["date"] = date
  json["short-description"] = shortDescription
  json["description"] = description
  json["videoURL"] = videoURL

  json["artists"] = artists
  
  return json
}

function submitInterview(e) {
  var form = e.parentElement
  var json = parseInterviewForm(form)
  
  var error = document.getElementById('error')
  if (json["error"]) {
    error.innerHTML = 'Error: ' + json['error']
    error.style.display = 'block'
    return
  } else {
    error.style.display = 'none'
  }
    
  console.log("Submitting interview creation with JSON:")
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

function updateInterview(e) {
  var form = e.parentElement
  var json = parseInterviewForm(form)
  
  var idInput = document.getElementById("interview-id")
  var id = idInput.value
  json["id"] = id
  
  console.log("Updating interview with JSON:")
  console.log(json)
  
  var formreq = new XMLHttpRequest()
  formreq.open(form.method, form.action, true)
  formreq.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  formreq.onreadystatechange = function () {
    location.replace("/app/interviews")
  }
  
  formreq.send(JSON.stringify(json))
}

function deleteInterview(id) {
  let delreq = new XMLHttpRequest()
  delreq.open("POST", "/api/interview/" + id + "/delete", true)
  delreq.onreadystatechange = function () {
    location.replace("/app/interviews")
  }
  
  delreq.send()
}
