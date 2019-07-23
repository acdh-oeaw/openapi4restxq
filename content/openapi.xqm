xquery version "3.1";
(:~
 : This library provides functions to prepare an OpenAPI description file for
 : documenting public REST-APIs made with RESTXQ. Its output is a JSON file that
 : can be used with swagger-ui.
 : @author Mathias Göbel, SUB Göttingen
 : @version 1.0
 : @see https://www.openapis.org/
 :)

module namespace openapi="https://lab.sub.uni-goettingen.de/restxqopenapi";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace pkg="http://expath.org/ns/pkg";
declare namespace repo="http://exist-db.org/xquery/repo";

declare variable $openapi:supported-methods := ("rest:GET", "rest:HEAD", "rest:POST", "rest:PUT", "rest:DELETE", "rest:method");

(:~
 : Prepares a JSON document conform to OpenAPI 3.0.2, usually to be stored as "openapi.json".
 : @param $target the collection to prepare the descriptor for, e.g. “/db/apps/application”
 :   :)
declare function openapi:json($target as xs:string)
as xs:string {
  openapi:main($target)
  => serialize(map{ "method": "json", "media-type": "application/json" })
};

(:~
 : Prepare OpenAPI descriptor for an installed package specified by its path in
 : the database.
 : @param $target the directory to prepare the descriptor for, e.g. file:base-dir()
 : @return complete OpenAPI description
 :)
declare function openapi:main($target as xs:string)
as map(*) {
  let $modules-uris := file:list($target, true())[openapi:xquery-resource(.)]!file:resolve-path(., $target)
  let $module :=
    for $module in $modules-uris
    let $test4rest := contains(file:read-text($module), "%rest:")
    where $test4rest
    return
      inspect:module($module)[.//annotation[@name = $openapi:supported-methods]]

  let $config-uri := $target || "/openapi-config.xml"
  let $config :=  if(doc-available($config-uri))
                  then doc($config-uri)/*
                  else doc(file:base-dir()|| "/../openapi-config.xml" )/*
  let $expath := doc($target || "/expath-pkg.xml")/*
  let $repo := doc($target || "/repo.xml")/*
  return
    map:merge((
    map{"openapi": "3.0.2"},
    openapi:paths-object($module, $config),
    openapi:servers-object($config/openapi:servers),
    openapi:info-object($expath, $repo, $config/openapi:info),
    openapi:tags-object($module, $config),
    openapi:components-object($config),
    openapi:security-requirement-object($config)
    ))
};

(:~
 : Prepare OAS3 Info Object
 : @see https://swagger.io/specification/#infoObject
 :)
declare function openapi:info-object($expath as element(pkg:package), $repo as element(repo:meta), $config as element(openapi:info))
as map(*) {
  map{ "info":
    map{
      "title": string($expath/pkg:title),
      "description": string($repo/repo:description),
      "termsOfService": string($config/openapi:termsOfService),
      "contact": openapi:contact-object($repo, $config/openapi:contact),
      "license": openapi:license-object($repo),
      "version": string($expath/@version)
    }
  }
};

(:~
 : Prepare a OAS Contact Object
 : @see https://swagger.io/specification/#contactObject
 :)
declare function openapi:contact-object($repo as element(), $config as element(openapi:contact))
as map(*) {
    map{
        "name": string($repo/repo:author[1]),
        "url": string($repo/repo:website[1]),
        "email": string($config/openapi:email)
        }
};

(:~
 : Prepare a OAS License Object
 : @see https://swagger.io/specification/#licenseObject
 :)
declare function openapi:license-object($repo as element(repo:meta))
as map(*) {
  let $licenseId := string($repo/repo:license)
  let $url := (map:get(openapi:spdx($licenseId), "seeAlso")?*)[1]
  return
    map{
      "name": $licenseId,
      "url": $url,
      "x-name-is-spdx": exists($url)
      }
};

(:~
 : Prepares a OAS3 Servers Object
 : @see https://swagger.io/specification/#serverObject
 :)
declare function openapi:servers-object($config as element(openapi:servers))
as map(*) {
  map{
      "servers": array {
        for $server in $config/openapi:server
        return
          map{
            "url": string($server/@url),
            "description": string($server)
          }
        }
  }
};

(:~
 : Prepare OAS3 Paths Object.
 : @see https://swagger.io/specification/#pathsObject
 :)
declare function openapi:paths-object($module as element(module)+, $config as element(openapi:config))
as map(*) {
  let $paths := $module/function/annotation[@name = "rest:path"]/literal => distinct-values()
  return
  map{
    "paths":
      map:merge((
        for $path in $paths
        let $functions := $module/function[annotation[@name = "rest:path"]/literal = $path]
        return
          map{
              $path => replace("\{\$", "{"):
                map:merge(($functions ! openapi:operation-object(., $config)))
          }
      ))
  }
};

(:~
 : Prepare OAS3 Operation Object.
 : @see https://swagger.io/specification/#operationObject
 :)
declare function openapi:operation-object($function as element(function), $config as element(openapi:config))
as map(*) {
  let $name := $function/@name
  let $desc := tokenize($function/description, "\n\s?\n\s?") ! normalize-space(.)
  let $see := $function/see
  let $deprecated := $function/deprecated
  let $tags := array {
      if($config/openapi:tags/openapi:tag/openapi:function[@name = $name])
      then
        if($config/openapi:tags/openapi:tag/openapi:function[@name = $name]/parent::openapi:tag/string(@method) = "exclusive")
        then $config/openapi:tags/openapi:tag/openapi:function[@name = $name]/parent::openapi:tag[@method = "exclusive"]/string(@name)
        else
            ($name => substring-before(":"),
            $config/openapi:tags/openapi:tag/openapi:function[@name = $name]/parent::openapi:tag/string(@name))
      else
        $name => substring-before(":")
  }
  return
  map:merge((
    for $method in $function/annotation[@name = $openapi:supported-methods]/@name
    let $methodName := if (ends-with($method, ':method')) 
      then lower-case($method/../literal[1])
      else substring-after(lower-case($method), "rest:")
    return
    map{
      $methodName:
      map:merge((
        map{ "summary": $desc[1]},
        $desc[2] ! map{ "description": .},
        map{ "tags": $tags},
        $see[1] ! map{"externalDocs": $see ! map{
          "url": normalize-space(.),
          "description": "the official documentation by the maintainer or a thrid-party documentation"}},
        $deprecated ! map{"deprecated": true()},
        openapi:parameter-object($function),
        openapi:responses-object($function),
        openapi:requestBody-object($function)
      ))
    }
  ))
};

declare function openapi:requestBody-object($function as element(function))
as map(*)? {
let $varParm := ($function/annotation[@name = ("rest:POST", "rest:PUT")]/literal[1], $function/annotation[@name = ("rest:method")]/literal[2])
return if(not(exists($varParm))) then () else
    let $name := replace($varParm, "\{|\}|\$", "")
    let $desc := string($function/argument[@name eq $name])
    let $example := string(($function/annotation[ends-with(@name, ":arg")][literal[1] eq $name])[1]/literal[2])
    let $consumes := (
      $function/annotation[ends-with(@name, ':consumes')]/literal,
      'application/xml'
    )[. != ""][1]
    return
    map{
        "requestBody":  map{
            "description": $desc||" Processed as variable: $" || $name,
            "content": map{
                $consumes: openapi:schema-object($function/argument[@name eq $name], $consumes, $example)
            },
            "required": true()
        }
    }
};

(:~
 : Prepare OAS3 Responses Object.
 : @see https://swagger.io/specification/#responsesObject
 :  :)
declare function openapi:responses-object($function as element(function))
as map(*){
  map{
    "responses":
    map{
      "200": map{
        "description": string($function/return),
        "content": openapi:mediaType-object($function)
      }
    }
 }
};

(:~
 : Prepare OAS3 Parameter Object.
 : @see https://swagger.io/specification/#parameterObject
 :  :)
declare function openapi:parameter-object($function as element(function))
as map(*) {
    map{
      "parameters": array{
          openapi:parameters-path($function),
          openapi:parameters($function, "query"),
          openapi:parameters($function, "header"),
          openapi:parameters($function, "cookie")
      }
    }
};

(:~
 : Prepares all PATH parameters for a given function
 : @param $function A function element from the inspect module
 : @see https://swagger.io/specification/#parameterObject
 : :)
declare function openapi:parameters-path($function as element(function))
as map(*)* {
    let $pathParameters :=
        $function/annotation[@name = "rest:path"][1]
            /tokenize(literal, "\{")
            [starts-with(., "$")]
            ! (.
                => substring-after("$")
                => substring-before("}")
            )

    for $parameter in $pathParameters
    let $name := replace($parameter, "\{|\$|\}", "")
    let $argument := $function/argument[@name eq $name]
    let $example := openapi:example($function, $name)
    let $basics := map:merge((
                map{
                    "name": $name,
                    "in": "path",
                    "required": true()},
                    openapi:schema-object($argument, 'text/plain', $example('example'))
    ))
    let $description := $function/argument[@name = $name]/text() ! map{ "description": .}
    return
        map:merge(($basics, $description, $example))

};

(:~
 : Prepares all QUERY, HEADER and COOKIE parameters for a given function
 : @param $function A function element from the inspect module
 : @see https://swagger.io/specification/#parameterObject
 : :)
declare function openapi:parameters($function as element(function), $source as xs:string)
as map(*)* {
    let $parameters := $function/annotation[@name = "rest:" || $source || "-param"]
    for $annotation in $parameters
        let $varName := string($annotation/literal[2]) => replace("\{|\$|\}", "")
        let $example := openapi:example($function, $varName)
        let $name := string($annotation/literal[1])
        let $argument := $function/argument[@name eq $varName]
        let $required :=
            (: not required when either a default value is present or the occurrence is ? or * :)
            not(exists($annotation/literal[3]) or $argument/@occurrence = ("?", "*"))
        let $basics :=
                map:merge((
                    map{
                        "name": $name,
                        "in": $source,
                        "required": $required
                        },
                        openapi:schema-object($argument, 'text/plain', $example('example'))
                ))
        let $description := $argument/text() ! map{ "description": .}
        return
            map:merge(($basics, $description, $example))
};

(:~
 : Prepare OAS3 Media Type Object.
 : @see https://swagger.io/specification/#mediaTypeObject
 :  :)
declare function openapi:mediaType-object($function)
as map(*) {
  let $produces := (
        string($function/annotation[ends-with(@name, ":produces")][1]),
        string($function/annotation[@name="output:media-type"]),
        string($function/annotation[@name="output:method"]/openapi:method-mediaType(string(.))),
        "application/xml"
      )[. != ""][1]
  return
      map:merge((
      map{
        $produces: openapi:schema-object($function/return, $produces, $function/annotation[ends-with(@name, ":assertEquals")]/literal[1])
      },
      subsequence($function/annotation[ends-with(@name, ":produces")], 2) ! map {
        string(.): openapi:schema-object($function/return, string(.), $function/annotation[ends-with(@name, ":assertEquals")]/literal[1])
      }))
};

(:~
 : Prepare OAS3 Schema Object.
 : @param $returns A element from the inspect-module() function,
 : @param $mime-type A mime type for return or body values or complex arguments
 : either *:returns or *:argument
 : @see https://swagger.io/specification/#mediaTypeObject
 :  :)
declare function openapi:schema-object($returns_or_argument as element(*), $mime-type as xs:string, $example as xs:string?)
as map(*)? {
  let $schema-from-example := if (normalize-space($example) ne '') then
    if (contains($mime-type, "xml")) then      
      let $root-element-name-from-type := replace(data($returns_or_argument/@type)[matches(., 'element\((.*)\)')], 'element\((.*)\)', '$1')
      let $root-element-name-from-example := try { local-name(parse-xml-fragment($example)/*) } catch * {()}
      let $root-element-name := ($root-element-name-from-type, $root-element-name-from-example, 'no-tag-name')[. != ""][1]
      return openapi:to-openapi-xml-schema(parse-xml-fragment($example))('properties')($root-element-name)
    else if (contains($mime-type, "json")) then openapi:to-openapi-json-schema(parse-json($example))
    else () else ()
  return map{ "schema":
    map:merge((
        map{
          "type": "string",
          "x-xml-type": string($returns_or_argument/@type)
        },
        if($returns_or_argument/@occurrence = ("*", "?"))
        then map{ "nullable": true() }
        else (),
        $schema-from-example
    ), map {'duplicates': 'use-last'})
  }
};

declare function openapi:tags-object($modules as element(module)+, $config as element(openapi:config))
as map(*) {
  map{
    "tags": array{
        for $module in $modules
        return
            map{
                "name": string($module/@prefix),
                "description": normalize-space($module/description)
            },
        for $tag in $config/openapi:tags/openapi:tag
        return
            map{
                "name": string($tag/@name),
                "description": normalize-space($tag)
            }
    }
  }
};

(:~
 : Create the components part of the openapi spec.
 : Stub: only reads basic http security scheme
 : @see https://swagger.io/specification/#componentsObject 
 :)
declare function openapi:components-object($config as element(openapi:config))
as map(*) {
  map {
    "components": map:merge((
      $config/openapi:components/openapi:schemas[1] ! map {
        "schemas": ""
      },
      $config/openapi:components/openapi:parameters[1] ! map {
        "parameters": ""
      },
      $config/openapi:components/openapi:responses[1] ! map {
        "responses": ""
      },
      $config/openapi:components/openapi:securitySchemes[1] ! map {
        "securitySchemes": openapi:security-scheme-object(.)
      }
    ))
  }
};

declare function openapi:security-scheme-object($securitySchemes as element(openapi:securitySchemes))
as map(*) {
  map:merge((
  $securitySchemes/openapi:securityScheme ! map {
    string(./@name): map:merge(( map {
      'description': normalize-space(./text()),
      'type': string(./openapi:type)
    },
    ./openapi:scheme[1] ! map {
      'scheme': string(.)
    }
    ))
  }))
};

(:~
 : Create the components part of the openapi spec.
 : Stub: only reads basic http security scheme
 : @see https://swagger.io/specification/#securityRequirementObject
 :)
declare function openapi:security-requirement-object($config as element(openapi:config))
as map(*)? {
  $config/openapi:security[1] ! map {
    "security": array {(
    ./openapi:SecurityRequirement ! map {
      string(./@name): [(: list of scope names for "oauth2" or "openIdConnect" :)]
    }
  )}
  }
};

(:~
 : Resolve an SPDX licenseId
 : @param a valid SPDX license code
 : @return a map with all SPDX data to the requested license
 :)
declare function openapi:spdx($licenseId as xs:string)
as map(*) {
let $collection-uri := file:base-dir() (: /id("restxqopenapi")/base-uri() :)
let $item :=
 (($collection-uri || "/../spdx-licenses.json")
  => json-doc())("licenses")?*[?licenseId = $licenseId]

return
    map:merge($item)
};

(:~
 : Get a media type from a method call to XQuery Serialization
 : @param $method One of the specified methods
 : @see https://www.w3.org/TR/xslt-xquery-serialization/
 :  :)
declare function openapi:method-mediaType($method as xs:string?)
as xs:string?{
    switch ($method)
        case "html" return "text/html"
        case "text" return "text/plain"
        case "xml" return "application/xml"
        case "xhtml" return "application/xhtml+xml"
        case "json" return "application/json"
        (: case "adaptive" return () :)
        default return ()
};

(:~
 : Prepare an example value based on XQSuite annotation
 : @param $function A function element from inspect module
 : @param $name The name of the argument to prepare an example for :)
declare function openapi:example($function as element(function), $name as xs:string)
as map(*)* {
    string(($function/annotation[ends-with(@name, ":arg")][literal[1] eq $name])[1]/literal[2])
    ! map{ "example": .}
};

declare function openapi:xquery-resource($baseuri as xs:string)
as xs:boolean {
     ends-with($baseuri, ".xqm")
  or ends-with($baseuri, ".xql")
  or ends-with($baseuri, ".xq")
};

declare function openapi:to-openapi-xml-schema($xml as node()) as map(*) {
    let $child-elements := for $child-element in $xml/(element(), @*)
                           return map{$child-element/local-name(): openapi:to-openapi-xml-schema($child-element)},
        $child-texts := for $child-text in $xml/(text()) return openapi:to-openapi-xml-schema($child-text)
    return map:merge((
        map {
        'type': if (exists($child-elements)) then 'object' else 'string' (: lots of castable as ... :),
        'xml': map:merge((map {'name': $xml/local-name()}, if ($xml instance of attribute()) then map {'attribute': true()} else ()))
        },
        if (exists($child-elements)) then map {'properties': map:merge($child-elements)} else (),
        if (exists($child-texts) or $xml instance of attribute()) then map {'example': xs:string($xml)} else ()))
};

declare function openapi:to-openapi-json-schema($json as map(*)) {
    let $child-objects := for $child-key in map:keys($json)
                          where $json($child-key) instance of map(*)
                          return map {$child-key: openapi:to-openapi-json-schema($json($child-key))},
        $leave-objects := for $leave-key in map:keys($json)
           where not($json($leave-key) instance of map(*))
           return map {$leave-key: map{
               'type': 'string',
               'example': $json($leave-key)}}
    return map {
      'properties': map:merge(($child-objects, $leave-objects)),
      'type': 'object'
    }
};
