function changePassword() {
  var error = document.getElementById('change-password-error')
  var success = document.getElementById('change-password-success')
  error.style.display = 'none'
  success.style.display = 'none'
  
  var newPassword1Input = document.getElementById('new-password1')
  var newPassword1 = newPassword1Input.value
  
  var newPassword2Input = document.getElementById('new-password2')
  var newPassword2 = newPassword2Input.value
  
  if (newPassword1 != newPassword2) {
    error.innerHTML = 'Error: Passwords must match'
    error.style.display = 'block'
    return
  }
  
  var json = {}
  json['new-password'] = newPassword1
  
  var req = new XMLHttpRequest()
  req.open('post', '/api/user/change-password', true)
  req.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  req.onreadystatechange = function() {
    if (req.readyState != req.DONE)
      return
      
    if (req.status != 200) {
      error.innerHTML = 'Failed to change password'
      error.style.display = 'block'
      return
    }
    
    success.innerHTML = "Password changed"
    success.style.display = 'block'
  }
  
  req.send(JSON.stringify(json))
}

function createAccount() {
  var error = document.getElementById('create-account-error')
  var success = document.getElementById('create-account-success')
  error.style.display = 'none'
  success.style.display = 'none'
  
  var usernameInput = document.getElementById('username-input')
  var username = usernameInput.value
  
  var passwordInput = document.getElementById('password-input')
  var password = passwordInput.value
  
  var json = {}
  json['username'] = username
  json['password'] = password
  
  var req = new XMLHttpRequest()
  req.open('post', '/api/user/create-account', true)
  req.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  req.onreadystatechange = function() {
    if (req.readyState != req.DONE)
      return

    if (req.status != 200) {
      error.innerHTML = 'Failed to create'
      error.style.display = 'block'
      return
    }
    
    success.innerHTML = "Account created"
    success.style.display = 'block'
  }
  
  req.send(JSON.stringify(json))
}
