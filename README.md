# Tracks

Tracks is a basic Controllers / Views framework written in Ruby and modeled after Ruby on Rails.  **ControllerBase** implements the base controller class, and **Router** provides routing capabilities.  

## ControllerBase

### Key Features

**ControllerBase** provides the following methods for descendent classes:

Method|Description
---|---
render(template_name) | Renders the file *views*/*controller_name*/***template_name***.*html.erb* into the application's main application.html.erb file.
render_content(content, content_type) | Renders content with the specified type
redirect_to(url) | Redirects to the specified URL
session | Maintains state across HTTP requests in a hash-like object
flash and flash.now | Similar to session but state is cleared after each request.
{before,after}_action | Specifies functions to run before/after the controller action. Use ```:only => []``` and ```:except =>``` options to limit them to specific actions.
protect_from_forgery | Protects against Cross-Site Request Forgery attacks. When enabled, a valid authenticity token must accompany all data submitted to the server.

You render the CSRF token into a hidden form field as follows:

```html
<input type="hidden" name="authenticity_token"
  value="<%= form_authenticity_token %>">
```

### Example Usage

In the example application ```controllers/gifs_controller.rb``` implements the application controller.

It's *show* and *search* actions do not explicitly render results, but instead rely on ControllerBase to automatically render the default namesake template when an action neither renders nor redirects.

```ruby
require_relative '../lib/controller_base'

class GifsController < ControllerBase
  protect_from_forgery

  def show
    @gifs = request("trending", limit: 5, rating: "G")
  end

  def search
    @gifs = request("search", q: params[:keyword], limit: 10, rating: "G",
      lang: "en")
  end

  ...

end
```

## Router

The `Router` maps urls to actions in custom controllers. For example,

```ruby
require_relative 'lib/router'

router = Router.new
router.draw do
  get Regexp.new("^/$"), GifsController, :show
  post Regexp.new("^/search$"), GifsController, :search
end
```

The first argument is the HTTP action. Next is a regular expression to match against the request path. Lastly you specify the class name of the target controller and the action to invoke.

Tracks automatically extracts parameters from the URL query string and makes them available through the controller's ```params``` method. For convenience, ```params``` accepts both strings and symbols to identity parameters

If the route path regular expression contains named groups, Tracks also extracts the matching portions of the URL and makes them available in ```params```.

## Middleware

Tracks includes these Rack middlewares to serve static assets and to handle errors:

Name | Description
----|----
**Static** | Serves static assets from the ```/assets``` folder. When possible, it infers the MIME type from the file extension and otherwise serves plain text.
**ShowExceptions** | Renders detailed errors messages when the controller raises an exception. The message includes the file name, line number and a snippet of the surrounding code.

### Putting it All Together

See [demo_server.rb](https://github.com/dextersealy/ruby-on-tracks/blob/master/demo_server.rb) for an example entry file.

### Running the Example app

The demo application displays trending GIFs of the day and allows you to search for GIFs by keyword.  To run it you need up-to-date versions of [Ruby](https://www.ruby-lang.org/en/) and [Bundler](http://bundler.io).

1. `git clone` [https://github.com/dextersealy/ruby-on-tracks](https://github.com/dextersealy/ruby-on-tracks)
2. `bundle install`
3. `ruby demo_server.rb`
4. Visit `http://localhost:3000`

## License

Tracks Copyright (c) Dexter Sealy

Tracks is free software; you can distribute it and/or modify it subject to the terms of the [MIT license](https://opensource.org/licenses/MIT).
