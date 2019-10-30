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
    
//    res = JSON.parse(req.response)
//    console.log(res)
//    
//    var error = document.getElementById('login-error');
//    if (res['error']) {
//      error.innerHTML = 'Error: ' + res['reason']
//      return
//    }
//    
//    var id = res['id']
//    var userId = res['userID']
//    var token = res['token']
    
    location.replace('/app')
  }

  req.send()
}
