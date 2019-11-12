function parseArticleForm(form) {
  var titleInput = document.getElementById("title-input")
  var title = titleInput.value
  if (title.trim() == "") {
    return {
      'error': 'Article must have a title'
    }
  }

  var date = form.date.value
  if (date == "") {
    return {
      "error": "Article must have a date"
    }
  }

  var authorInput = document.getElementById("author-input")
  var author = authorInput.value

  if (author.trim() == "") {
    return {
      "error": "Article must have an author"
    }
  }

  var authorLinkInput = document.getElementById("author-link-input")
  var authorLink = authorLinkInput.value

  var contentInput = document.getElementById("content-input")
  var content = contentInput.value

  if (content.trim() == "") {
    return {
      "error": "Article must have some content"
    }
  }

  var json = {}
  json["title"] = title
  json["date"] = date
  json["author"] = author
  json["authorLink"] = authorLink
  json["content"] = content

  return json
}

function submitArticle(e) {
  var form = e.parentElement
  var json = parseArticleForm(form)

  var error = document.getElementById('error')
  if (json["error"]) {
    error.innerHTML = 'Error: ' + json['error']
    error.style.display = 'block'
    return
  } else {
    error.style.display = 'none'
  }

  console.log("Submitting article creation with JSON:")
  console.log(json)

  var formreq = new XMLHttpRequest()
  formreq.open(form.method, form.action, true)
  formreq.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  formreq.onreadystatechange = function () {
    console.log("... Submitted. Reloading page")
    location.reload(true)
  }

  formreq.send(JSON.stringify(json))
}

function updateArticle(e) {
  var form = e.parentElement
  var json = parseArticleForm(form)

  var idInput = document.getElementById("article-id")
  var id = idInput.value
  json["id"] = id

  console.log("Updating article with JSON:")
  console.log(json)

  var formreq = new XMLHttpRequest()
  formreq.open(form.method, form.action, true)
  formreq.setRequestHeader("Content-Type", "application/json; charset=UTF-8")
  formreq.onreadystatechange = function () {
    location.replace("/app/news")
  }

  formreq.send(JSON.stringify(json))
}
