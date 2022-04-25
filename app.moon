lapis = require 'lapis'
redis = require 'resty.redis'
config = require("lapis.config").get!
import respond_to from require 'lapis.application'

math.randomseed(ngx.now())

connect_redis = ->
  red = with redis\new()
    \set_timeouts 1000, 1000, 1000
  ok, err = red\connect config.redis_addr, 6379
  if err
    nil, err
  else
    red, nil

class extends lapis.Application
  @enable 'etlua'
  layout: 'layout'

  '/': =>
    @html ->
      form method: 'post', action: @url_for('shorten'), ->
        input name: 'url', placeholder: 'cool.website/thing', autocomplete: 'off', autocapitalize: 'off', spellcheck: 'false', required: true, autofocus: true
        button tabindex: '-1', 'slugg it'

  [shorten: '/shorten']: respond_to {
    POST: =>

      basen = (n, b) ->
          assert(n >= 0)
          n = math.floor(n)
          if not b or b == 10 then return tostring(n)

          digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
          t = {}
          sign = ''

          d = (n % b) + 1
          n = math.floor(n / b)
          table.insert(t, 1, digits\sub(d, d))
          while n != 0
            d = (n % b) + 1
            n = math.floor(n / b)
            table.insert(t, 1, digits\sub(d, d))

          sign .. table.concat(t, '')

      randomid = -> basen(math.floor(math.random(1000, 26 ^ 5)), 52)
      id = randomid!
      red, err = connect_redis!
      if err
        return err

      red\hset("url:#{id}", 'url', @params.url, 'clicks', 0)

      @html ->
        h1 @build_url @url_for "open_link", id: id
  }

  [open_link: '/:id']: =>
    red, err = connect_redis!
    if err
      return err

    url, err = red\hget("url:#{@params.id}", 'url')
    if err
      return err

    if url == ngx.null
      return "#{@params.id} not found"

    update, err = red\hincrby("url:#{@params.id}", 'clicks', 1)
    if err
      return err

    if url\find('^https?://') == nil
      url = "http://#{url}"

    redirect_to: url

  [list: '/list']: =>
    red, err = connect_redis!
    if err
      return err

    urls, err = red\keys("url:*")
    if err
      return err

    @html ->
      ul style: "width: 100vw; height: 100vh; overflow: scroll;", ->
        for url in *urls
          dest, err = red\hget(url, 'url')
          if err
            li "#{url} => #{err}"
          else
            li "#{url} => #{dest}"
