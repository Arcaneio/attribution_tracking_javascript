get_first_referrer = ->
  {
    first_referrer: (get_cookie('first_referrer') || get_latest_referrer()['latest_referrer'])
  }

get_latest_referrer = ->
  ref       = document.referrer
  attr_host = attribution_host(ref)
  bad_host  = !attr_host?
  our_host  = attr_host == attribution_host(document.location)

  if !ref? || our_host || bad_host
    latest_ref = get_cookie('latest_referrer')
  else
    latest_ref = attr_host

  {
    latest_referrer: latest_ref
  }

get_first_utm = ->
  first = {
    first_utm_name:     get_cookie('first_utm_source'),
    first_utm_source:   get_cookie('first_utm_source'),
    first_utm_medium:   get_cookie('first_utm_medium'),
    first_utm_term:     get_cookie('first_utm_term'),
    first_utm_content:  get_cookie('first_utm_content')
  }

  if !first['first_utm_name']?
    for k,v of get_latest_utm()
      first[k.replace('latest_','first_')] = v

  return first

get_latest_utm = ->
  params = queryParams()

  name    = params['utm_campaign']
  source  = params['utm_source']
  medium  = params['utm_medium']
  term    = params['utm_term']
  content = params['utm_content']

  unless name?
    name    = get_cookie('latest_utm_name')
    source  = get_cookie('latest_utm_source')
    medium  = get_cookie('latest_utm_medium')
    term    = get_cookie('latest_utm_term')
    content = get_cookie('latest_utm_content')

  {
    latest_utm_name:     name
    latest_utm_source:   source
    latest_utm_medium:   medium
    latest_utm_term:     term
    latest_utm_content:  content
  }


queryParams = ->
  query = document.location.search.substr(1)
  result = {}
  query.split("&").forEach (part) ->
    item = part.split("=")
    result[item[0]] = decodeURIComponent(item[1])
  result

attribution_host = (url) ->
  return null if !url? or url==''
  url = "http://#{url}" unless String(url).indexOf('http')==0
  l = document.createElement("a")
  l.href = url
  l.hostname && l.hostname.replace(/^www\./i,'').toLowerCase()

get_option = (key) ->
  defaults = {
    'cookie_domain': document.location
  }

  options = merge(defaults, window.attribution_tracking_options)

  options[key]

set_cookie = (name, value) ->
  expires = new Date( (new Date()).getTime() + (30 * 1000 * 60 * 60 * 24) )

  domain = get_option('cookie_domain')

  document.cookie = [
    encodeURIComponent(name), '=', JSON.stringify(value),
    '; expires=' + expires.toUTCString(),
    '; domain=' + attribution_host(domain)
  ].join('')

get_cookie = (name) ->
  value = "; " + document.cookie
  parts = value.split("; " + name + "=")
  return if (parts.length == 2) then parts.pop().split(";").shift() else null

merge = (a, b={}) ->
  for k,v of b
    a[k] = v
  a

guid = ->
  s4 = -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
  "#{s4()}#{s4()}-#{s4()}-#{s4()}-#{s4()}-#{s4()}#{s4()}#{s4()}"

main = ->
  attr_data = {
    distinct_analytics_id: guid()
  }

  merge(attr_data, get_first_utm())
  merge(attr_data, get_latest_utm())
  merge(attr_data, get_first_referrer())
  merge(attr_data, get_latest_referrer())

  window.current_attribution_data ||= {}

  for key, value of attr_data
    set_cookie(key, value)
    window.current_attribution_data[key] = value

  attr_data


main()
