#!/bin/bash

### A "Good luck" script initializes a project.

##### The only optional argument for the script is the name of the project.
     PROJECT=$1 ; shift
     FRESH=TRUE

##### When no argument is given the project name is detected by the current directory name.
##### In that case it is thought, it is a rerun of this script from project directory.
     if [ -z "$PROJECT" ] ; then
         PROJECT=$(basename $(pwd))
         FRESH=FALSE
     fi

##### Safety guard not to create a probably unwanted "child" project with the same name.
     if [ "_$PROJECT" == "_$(basename $(pwd))" -a -e package.json ] ; then
         FRESH=FALSE
     fi

     echo "Setup project $PROJECT"

##### This option lets the script stop, if an command return value is not zero.
##### In the shell world is this an indicator for an error.
     set -e

##### This option makes that each command is echoed before execution.
##### This helps during development but is commented out for the final version.
     #set -x

##### Only when it is a fresh run the directory is created, the current working directory is changed to this directory and package.json file is created.
     if [ "$FRESH" == TRUE ] ; then
          mkdir -p $PROJECT
          cd $PROJECT

          npm init -y
     fi

##### The Dependencies with which I like to play:
##### * [bulma - a modern and clean CSS framework](https://bulma.io/)
##### * [codemirror - a versatile programming editor](https://codemirror.net/)
##### * [diffhtml - looks like a good swiss army knife for frontend programming fun](https://diffhtml.org)
##### * [nano-css - program css in javascript](https://github.com/streamich/nano-css#readme)
     DEPS="bulma codemirror diffhtml nano-css"
     npm install --save $DEPS

##### The development dependencies I like currently for my projects:
##### * [cute-dev-server - leightweight developments http server](https://www.npmjs.com/package/cute-dev-server)
##### * [html - command line formatter for html](https://www.npmjs.com/package/html)
##### * [jasmine - the test framework of choice](https://jasmine.github.io/)
##### * [npe - easily edit json files via command line](https://www.npmjs.com/package/npe)
     DEVDEPS="cute-dev-server html jasmine npe"
     npm install --save-dev $DEVDEPS

##### Here npe is used to edit the package.json file, which is the default.
##### Other json files can  you adress with --package=file.json option.
     npx npe version "0.1.0"
     npx npe scripts.serve "npx cute public"

##### The following part is optional and shows the disk usage of node_modules.
##### It uses perl for improving the output of disk usage(du) command.
     space_usage () {
         local dir=$1; shift
         echo "Space used by directory $dir"
         du -h --max-depth=1 $dir/ | perl -n -E'
         ($size,$file)=split /\s+/;
         $file=~s/^'$dir'\///;
         $r{$file}=$size;
         END{
             for $k(sort keys %r){
                 printf("%-40s %6s\n",$k?$k:"'$dir' directory",$r{$k})
             }
         }'
     }
     space_usage node_modules

##### Creating an old school webspace.
     mkdir -p public
     mkdir -p public/css
     mkdir -p public/js

##### Simply copy the assets into this space.
     NM=node_modules
     cp $NM/bulma/css/bulma.css public/css/
     cp $NM/bulma/css/bulma.css.map public/
     cp $NM/codemirror/lib/codemirror.js public/js/
     cp $NM/codemirror/lib/codemirror.css public/css/
     cp $NM/diffhtml/dist/diffhtml.js public/js/

##### Store the copied js and css file names for later usage.
     JS=$(ls public/js)
     CSS=$(ls public/css)

##### Generate the index.html for the webspace.
##### Note the - sign before __END__. This makes indentation in a multiline string possible.
##### This is also something, what should not run in a unsecure environment, because of unchecked shell input.
    GEN_INDEX_HTML=$(cat <<-__END__

    const js="$JS".split(/\s+/);
    const css="$CSS".split(/\s+/);
    __END__
    )

##### The HTML generating script is only splitted into chunks for blogging purpose.
##### This chunk imports diffhtml.
    GEN_INDEX_HTML="$GEN_INDEX_HTML"$(cat <<-__END__
    const diffhtml = require( "diffhtml" );
    const h = diffhtml.createTree;
    const toString = diffhtml.toString;
    __END__
    )

##### Setup the document strucure and load the assets.
    GEN_INDEX_HTML="$GEN_INDEX_HTML"$(cat <<-__END__
    console.log("<!DOCTYPE html>");

    let head = h('head', null, [
         h('title', null, ["Fresh project $PROJECT -- Good luck!"]),
         h('meta', {charset: "utf-8"}),
         h('meta', {name: "viewport", content: "width=device-width, initial-scale=1"}),
         css.map(f => h('link', {rel: "stylesheet", href: ["./css/",f].join("")})),
         js.map(f => h('script', {src: ["./js/",f].join("")}))
    ]);
    let body = h('body');
    let html = h('html', null, [head,body]);
    __END__
    )

##### Load the page content from a separate file _body.html and inject it into the document.
##### Finally make a string from the structure and send them to stdout.
    GEN_INDEX_HTML="$GEN_INDEX_HTML"$(cat <<-__END__
    let fs = require('fs');
    try {
        let bodyhtml = fs.readFileSync( "./_body.html", "utf8");
        diffhtml.innerHTML(body, bodyhtml);
    }
    catch (err) {
        console.warn("Can not load _body.html");
        console.error(err);
    }
    console.log( toString(html) );
    __END__
    )


##### The code is piped into node and output is nicely formatted with the html tool.
    echo $GEN_INDEX_HTML | node --use-strict | npx html >public/index.html
    space_usage public

##### Initialize the git ignore with a bare minimum.
    if [ $FRESH == TRUE ]; then
        echo node_modules >.gitignore
        echo package-lock.json >>.gitignore
    fi

##### Prepare the first git commit.
    git add .
    git status

##### This is my first hashnode post and a kind of comeback into coding.
##### You can find the [full script](https://github.com/giftnuss/good-luck/blob/master/start-js-toy.bash) under my github account.
##### Hopefully it inspires you to share a starter script too.
##### Good bye and
    echo "Good Luck!"
