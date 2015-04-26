assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
scribe = require cwd + '/lib/scribe'
fixture = require cwd + '/test/fixtures/scribe.json'
chalk = require 'chalk'
path = require 'path'
checkbox = require 'markdown-it-checkbox'
cheerio = require 'cheerio'

(($)->
    "use strict"
    try
        harness = (method)->
            if fixture.tests[method]?
                return fixture.tests[method]
            console.log chalk.red "No fixture for #{method} found, are you sure you added it to fixtures/scribe.json file?"
            return null
        reset = ()->
            scribe.json()
        beforeEach reset
        describe 'Scribe', ()->

            describe '.readFile', ()->
                it 'should read a file and return a parsed object', (done)->
                    list = harness 'readFile'
                    finish = _.after list.length, done
                    _.each list, (file)->
                        adjustedPath = path.resolve __dirname, file
                        $.readFile adjustedPath, (e, o)->
                                o.should.be.ok
                                o.attributes.should.be.ok
                                o.content.should.be.ok
                                finish()
                                return
                        return
                return

            describe '.readFileAsPromise', ()->
                it 'should read a file and return a promise which returns a parsed object', (done)->
                    list = harness 'readFile'
                    finish = _.after list.length, done
                    _.each list, (file)->
                        adjustedPath = path.resolve __dirname, file
                        $.readFileAsPromise(adjustedPath).then (o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()
                        , (e)->
                            console.log "There was an error during readFileAsPromise", e
                            if e.stack?
                                console.log e.stack

            describe '.readRaw', ()->
                it 'should read raw content and return a parsed object', (done)->
                    list = harness 'readRaw'
                    finish = _.after list.length, done
                    _.each list, (content)->
                        $.readRaw content, (e, o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()

                it 'should read yaml content and return a parsed object', (done)->
                    list = harness 'readYaml'
                    $.yaml()
                    finish = _.after list.length, done
                    _.each list, (content)->
                        $.readRaw content, (e, o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()

            describe '.readRawAsPromise', ()->
                it 'should read raw content and return a promise which returns a parsed object', (done)->
                    list = harness 'readRaw'
                    finish = _.after list.length, done
                    _.each list, (content)->
                        $.readRawAsPromise(content).then (o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()
                        , (e)->
                            console.log "There was an error during readRawAsPromise", e
                            if e.stack?
                                console.log e.stack

            describe '.renderer', ()->

                it "should allow for adding plugins to the render function", ()->
                    $.renderer.should.have.property 'use'
                    $.renderer.use.should.be.ok

            describe ".render", ()->

                it 'should throw an error when attempting to set render to a non-function', ()->
                    (->
                        $.render = false
                    ).should.throwError
                    (->
                        $.render = {}
                    ).should.throwError

                it 'should be able to use a different render function when rendering', (done)->
                    list = harness 'readFile'
                    finish = _.after (list.length + 1), done
                    oneCall = _.once finish
                    clone = _.wrap $.render, (fx)->
                        outcome = fx.apply $, _.rest arguments
                        oneCall()
                        return outcome
                    $.render = clone
                    _.each list, (file)->
                        adjustedPath = path.resolve __dirname, file
                        $.readFile adjustedPath, (e, o)->
                                o.should.be.ok
                                o.attributes.should.be.ok
                                o.content.should.be.ok
                                finish()
                                return
                        return
                
                it 'should be able to use plugins added via .renderer.use', ()->
                    $.renderer.use checkbox
                    num = Math.round Math.random() * 4e3
                    $dom = cheerio.load $.render("[ ] #{num}")
                    $input = $dom('input')
                    $input.length.should.not.equal 0
                    $dom.html().should.equal """<p><input type="checkbox" id="checkbox0"><label for="checkbox0">#{num}</label></p>\n"""


        return
    catch e
        console.warn "Error during Scribe testing: ", e
        if e.stack?
            console.warn e.stack
    
)(scribe)