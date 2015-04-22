assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
scribe = require cwd + '/lib/scribe'
fixture = require cwd + '/test/fixtures/scribe.json'
chalk = require 'chalk'
path = require 'path'

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
        return                   
    catch e
        console.warn "Error during Scribe testing: ", e
        if e.stack?
            console.warn e.stack
    
)(scribe)