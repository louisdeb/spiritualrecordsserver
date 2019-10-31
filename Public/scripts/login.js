function login() {
  var usernameInput = document.getElementById('username-input')
  var username = usernameInput.value
  
  var passwordInput = document.getElementById('password-input')
  var password = passwordInput.value
  
  var auth = btoa(username + ":" + password)
  
  var req = new XMLHttpRequest()
  req.open('post', '/api/user/', true)
  req.setRequestHeader('Authorization', 'Basic ' + auth)
  req.onreadystatechange = function() {
    if (req.readyState != req.DONE)
      return
    
    if (req.status != 200) {
      var error = document.getElementById('login-error')
      error.innerHTML = "Failed to log in"
      error.display = 'block'
      return
    }
    
    location.replace('/app')
  }

  req.send()
}
