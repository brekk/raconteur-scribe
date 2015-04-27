# raconteur-scribe

The scribe is tied to the [raconteur][] module, which offers additional functionality (such as easy template management and a clean programmatic interface) but you can use this module independently as well.

[raconteur]: https://www.npmjs.com/package/raconteur "The raconteur module"

## Installation

    npm install raconteur-scribe --save

## Invocation

    var scribe = require('raconteur-scribe');

### scribe

The scribe is a tool for converting content (think markdown / post format) into a more reusable object format which can resolve itself to HTML, but one which also has easy-to-create metadata.

In addition to the standard markdown you probably know and love, because we're using the `marked` library internally, you can modify and extend the existing renderer. (See [below][custom-renderer] for more details.)

[custom-renderer]: #custom-renderer "Rendering with a custom markdown renderer"

#### Metadata

We're using the `yaml-front-matter` and `json-front-matter` libraries under the hood, and that allows us to quickly add custom metadata to any content.

Here's an example post, using a combination of json-front-matter and markdown:

**example-post.md**:

    {{{
        "title": "The Title",
        "tags": ["a", "b", "c"],
        "date": "1-20-2015",
        "author": "brekk"
    }}}
    # Learning 
    Lorem ipsum dolor sit amet adipiscine elit.

**yaml-example-post.md**

    ---
    title: The Title
    tags: [a, b, c]
    date: 1-20-2015
    author: brekk
    ---
    # Learning 
    Lorem ipsum dolor sit amet adipiscine elit.

We can easily reference any of those properties in our template later using Crier module, but more on that shortly.

Here's an example of using the scribe module.

    var scribe = require('raconteur-scribe');
    var file = "./example-post.md";

We can use `scribe.readFile`, which follows the standard node-style callback (function(error, data)) and reads a markdown file into memory:

    scribe.readFile(file, function(error, data){
        if (!!error){
            console.log("error during read", error);
            return;
        }
        console.log(data.attributes);
        // prints attribute hash from file above: {title, tags, date, author}
        console.log(data.content);
        // prints markdown body as HTML
    });

We can use `scribe.readRaw`, which does the same thing as above but reads the content as a raw string:

    scribe.readRaw("{{{"title": "Hello World"}}}\n*hello* stranger.", function(error, data){
        if (error) {
            console.log(error);
            return;
        }
        console.log(data.attributes);
        // prints attribute hash from raw string above: {title}
        console.log(data.content);
        // prints markdown body as HTML
    });

Finally, we can use the promise-based version of either of those methods, `scribe.readFileAsPromise` and `scribe.readRawAsPromise` respectively, which don't expect the callback and instead return a promise:

    var happy = function(data){
        console.log(data.attributes);
        // prints attribute hash from raw string above: {title}
        console.log(data.content);
        // prints markdown body as HTML
    };
    var sad = function(error){
        console.log("error during readRaw", error.toString());
    };
    // scribe.readFileAsPromise("./example-post.md").then(happy, sad);
    // or
    scribe.readRawAsPromise("{{{"title": "Hello World"}}}\n*hello* stranger.").then(happy, sad);

##### Rendering with a custom markdown renderer

If you have a custom renderer (an instance of the `marked.renderer`), you can set it on a scribe using `scribe.setRenderer(customRendererInstance)`.