function login() {
  var usernameInput = document.getElementById('username-input')
  var username = usernameInput.value
  
  var passwordInput = document.getElementById('password-input')
  var password = passwordInput.value
  
  var json = {}
  json['username'] = username
  json['password'] = password
  
  var auth = btoa(username + ":" + password)
  
  var req = new XMLHttpRequest()
  req.open('post', '/api/user', true)
  req.setRequestHeader('Authorization', 'Basic ' + auth)
  req.onreadystatechange = function() {
    console.log("... Submitted. Reloading page")
    location.reload('/app')
  }
  
  req.send(JSON.stringify(json))
}
