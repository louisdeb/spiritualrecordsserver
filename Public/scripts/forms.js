function toggleShowCreateForm() {
  var form = document.getElementsByClassName("create-form")[0]
  form.style.display = form.style.display == "none" ? "block" : "none"
}

function deleteObject(objectRoute, id, redirect) {
  var really = confirm("Really want to delete this?")
  if (!really) { return }

  var req = new XMLHttpRequest()
  req.open('post', '/api/' + objectRoute + '/' + id + '/delete', true)
  req.onreadystatechange = function() {
    console.log("... Submitted. Reloading page")
    location.replace(redirect)
  }
  req.send()
}
