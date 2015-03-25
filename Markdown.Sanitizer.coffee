do ->
  sanitizeHtml = (html) ->
    html.replace /<[^>]*>?/gi, sanitizeTag

  sanitizeTag = (tag) ->
    return tag if tag.match(basic_tag_whitelist) or tag.match(a_white) or tag.match(img_white)
    ''

  #/ <summary>
  #/ attempt to balance HTML tags in the html string
  #/ by removing any unmatched opening or closing tags
  #/ IMPORTANT: we *assume* HTML has *already* been 
  #/ sanitized and is safe/sane before balancing!
  #/ 
  #/ adapted from CODESNIPPET: A8591DBA-D1D3-11DE-947C-BA5556D89593
  #/ </summary>

  balanceTags = (html) ->
    return '' if html == ''
    re = /<\/?\w+[^>]*(\s|$|>)/g
    # convert everything to lower case; this makes
    # our case insensitive comparisons easier
    tags = html.toLowerCase().match(re)

    # no HTML tags present? nothing to do; exit now
    tagcount = (tags or []).length
    return html if tagcount == 0

    ignoredtags = '<p><img><br><li><hr>'
    tagpaired = tagremove = []
    needsRemoval = false

    # loop through matched tags in forward order
    for ctag, tag of tags
      tagname = tag.replace(/<\/?(\w+).*/, '$1')
      # skip any already paired tags
      # and skip tags in our ignore list; assume they're self-closed
      continue if tagpaired[ctag] or ignoredtags.search('<' + tagname + '>') > -1
      match = -1
      if !/^<\//.test(tag)
        # this is an opening tag
        # search forwards (next tags), look for closing tags
        ntag = ctag + 1
        while ntag < tagcount
          if !tagpaired[ntag] and tags[ntag] == '</' + tagname + '>'
            match = ntag
            break
          ntag++
      if match == -1
        needsRemoval = tagremove[ctag] = true
      else
        tagpaired[match] = true
      # mark paired
    return html if !needsRemoval
    # delete all orphaned tags from the string
    ctag = 0
    html = html.replace(re, (match) ->
      res = if tagremove[ctag] then '' else match
      ctag++
      res
    )
    html

  if typeof exports == 'object' and typeof require == 'function'
    # we're in a CommonJS (e.g. Node.js) module
    output = exports
    Converter = require('./Markdown.Converter').Converter
  else
    output = window.Markdown
    Converter = output.Converter

  output.getSanitizingConverter = ->
    converter = new Converter
    converter.hooks.chain 'postConversion', sanitizeHtml
    converter.hooks.chain 'postConversion', balanceTags
    converter

  # (tags that can be opened/closed) | (tags that stand alone)
  basic_tag_whitelist = /^(<\/?(b|blockquote|code|del|dd|dl|dt|em|h1|h2|h3|i|kbd|li|ol(?: start="\d+")?|p|pre|s|sup|sub|strong|strike|ul)>|<(br|hr)\s?\/?>)$/i
  # <a href="url..." optional title>|</a>
  a_white = /^(<a\shref="((https?|ftp):\/\/|\/)[-A-Za-z0-9+&@#\/%?=~_|!:,.;\(\)*[\]$]+"(\stitle="[^"<>]+")?\s?>|<\/a>)$/i
  # <img src="url..." optional width  optional height  optional alt  optional title
  img_white = /^(<img\ssrc="(https?:\/\/|\/)[-A-Za-z0-9+&@#\/%?=~_|!:,.;\(\)*[\]$]+"(\swidth="\d{1,3}")?(\sheight="\d{1,3}")?(\salt="[^"<>]*")?(\stitle="[^"<>]*")?\s?\/?>)$/i
  return
