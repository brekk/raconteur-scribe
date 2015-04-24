_ = require 'lodash'
promise = require 'promised-io/promise'
pfs = require 'promised-io/fs'
Deferred = promise.Deferred
marked = require './renderer'
jsonmatter = require 'json-front-matter'
yamlmatter = require('yaml-front-matter').loadFront

module.exports = Scribe = {}
debug = require('debug') 'raconteur:scribe'

___ = require('parkplace').scope Scribe

___.guarded "_state", {
    yaml: false
    json: true
}

___.guarded '_yaml', {
    set: (value)->
        @_state.yaml = value
        @_state.json = !value
    get: ()->
        return @_state.yaml
}, true

___.guarded '_json', {
    set: (value)->
        @_state.json = value
        @_state.yaml = !value
    get: ()->
        return @_state.json
}, true

___.readable 'yaml', ()->
    debug "setting yaml mode to true!"
    @_yaml = true
    return Scribe

___.readable 'json', ()->
    debug "setting json mode to true!"
    @_json = true
    return Scribe

___.secret '_renderer', marked

___.guarded 'setRenderer', (renderer)->
    if renderer? and _.isFunction renderer
        debug 'Setting custom renderer function'
        @_renderer = renderer
    return @

___.guarded 'getRenderer', ()->
    return @_renderer

___.guarded 'handleFrontMatter', (frontdata, cb)->
    try
        unless frontdata?
            throw new Error "Expected data from jsonmatter. Have you added {{{metadata}}} to your post?"
        else
            debug "handling frontmatter data", Scribe._state.json
            debug frontdata
            callbackable = cb? and _.isFunction cb
            if frontdata.body? and frontdata.attributes?
                {body, attributes} = frontdata
                renderer = @getRenderer()
                output = renderer body
                if output?
                    post = {
                        attributes: attributes
                        content: output
                        # raw: body
                    }
                    if callbackable
                        debug "sending back post", post
                        cb null, post
                        return
            else
                if callbackable
                    cb new Error "Expected frontdata.body and frontdata.attributes."
                return
        if callbackable
            cb new Error "Improper markdown conversion."
    catch e
        debug "Error during handling of jsonmatter: %s", e.toString()
        if e.stack?
            console.log e.stack
        if cb?
            cb e

___.guarded 'eatYamlContent', (yamlRawContent)->
    out = {
        body: yamlRawContent.__content
        attributes: {}
    }
    # delete yamlRawContent.__content
    out = _(yamlRawContent).map((val, key)->
        item = {}
        if key is '__content'
            item.body = val
        else
            item.attributes = item.attributes or {}
            item.attributes[key] = val
        return item
    ).reduce((collection, iter)->
        if iter.attributes? and collection.attributes?
            collection.attributes = _.extend collection.attributes, iter.attributes
        else
            collection = _.extend collection, iter
        return collection
    , {})
    yamlRawContent = out
    return yamlRawContent

___.readable 'readRaw', (raw, cb)->
    try
        self = Scribe
        if !cb? or !_.isFunction cb
            throw new TypeError "Expected callback to be a function."
        unless _.isString raw
            cb new TypeError "Expected raw to be a string."
            return
        debug "Parsing data from raw string."
        parser = jsonmatter.parse
        if @_yaml
            yamlRegex = /^-{3}/
            if Scribe._state.yaml and yamlRegex.test raw
                parser = (input)->
                    return self.eatYamlContent yamlmatter input
        parsed = parser raw
        if @_yaml and parsed?.__content?
            debug "using yaml!"
            out = {
                body: parsed.__content
                attributes: {}
            }
            # delete parsed.__content
            _.each parsed, (val, key)->
                if key isnt '__content'
                    out.attributes[key] = val
            parsed = out
        if parsed?
            debug "Successfully parsed.", parsed
            self.handleFrontMatter parsed, cb
        else
            throw new Error "Nothing parsed from jsonmatter."
    catch e
        debug "Error during readRaw: %s", e.toString()
        if e.stack?
            console.log e.stack
        if cb? and _.isFunction cb
            cb e
    

___.readable 'readFile', (file, cb)->
    try
        self = @
        if !cb? or !_.isFunction cb
            throw new TypeError "Expected callback to be a function."
        debug "Parsing data from a file: %s", file
        fileReadOp = pfs.readFile file, {
          charset: 'utf8'
        }
        bad = (e)->
            cb e
            return
        good = (success)->
            # cb null, success
            self.readRaw success.toString(), cb
            return
        fileReadOp.then good, bad
        return

    catch e
        debug "Error during readFile: %s", e.toString()
        if e.stack?
            console.log e.stack
        if cb? and _.isFunction cb
            cb e

___.readable 'readRawAsPromise', (raw)->
    d = new Deferred()
    self = Scribe
    self.readRaw raw, (err, data)->
        if err?
            debug "Error during readRawAsPromise: %s", err.toString()
            d.reject err
            return
        d.resolve data
    return d

___.readable 'readFileAsPromise', (file)->
    d = new Deferred()
    self = Scribe
    self.readFile file, (err, data)->
        if err?
            debug "Error during readFileAsPromise: %s", err.toString()
            d.reject err
            return
        d.resolve data
    return d