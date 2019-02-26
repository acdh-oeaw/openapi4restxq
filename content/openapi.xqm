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

declare %private variable $openapi:supported-methods := ("rest:GET", "rest:HEAD", "rest:POST", "rest:PUT", "rest:DELETE");

(:~
 : Prepares a JSON document usually to be stored as "openapi.json".
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
 : @param $target the collection to prepare the descriptor for, e.g. “/db/apps/application”
 : @return complete OpenAPI description
 :)
declare function openapi:main($target as xs:string)
as map(*) {
  let $modules-uris := collection($target)[ends-with(base-uri(), ".xqm")]/base-uri()
  let $module :=
    for $module in $modules-uris
    let $inspect := inspect:inspect-module($module)
    where $inspect/function/annotation/string(@name) = $openapi:supported-methods
    return
        $inspect

  let $config-uri := $target || "/openapi-config.xml"
  let $config := if(doc-available($config-uri))
                then doc($config-uri)/*
                let $config := if(doc-available($config-uri))
              then doc($config-uri)/*
              else doc( replace(system:get-module-load-path(), '^(xmldb:exist://)?(embedded-eXist-server)?(.+)$', '$3') || "/openapi-config.xml" )/*
  let $expath := doc($target || "/expath-pkg.xml")/*
  return
    map:merge((
    map{"openapi": "3.0.2"},
    openapi:paths-object($module),
    openapi:servers-object($config/openapi:servers),
    openapi:info-object($expath, $repo, $config/openapi:info),
    openapi:tags-object($module)
    ))
};

(:~
 : Prepare OAS3 Info Object
 : @see https://swagger.io/specification/#infoObject
 :)
declare %private function openapi:info-object($expath as element(pkg:package), $repo as element(repo:meta), $config as element(openapi:info))
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
declare %private function openapi:contact-object($repo as element(), $config as element(openapi:contact))
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
declare %private function openapi:license-object($repo as element(repo:meta))
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
declare %private function openapi:servers-object($config as element(openapi:servers))
as map(*) {
  map{
      "servers":[
        for $server in $config/openapi:server
        return
          map{
            "url": string($server/@url),
            "description": string($server)
          }
        ]
  }
};

(:~
 : Prepare OAS3 Paths Object.
 : @see https://swagger.io/specification/#pathsObject
 :)
declare %private function openapi:paths-object($module as element(module)+)
as map(*) {
  map{
    "paths":
      map:merge((
        $module/function[annotation/@name = "rest:path"] ! openapi:operation-object(.)
      ))
  }
};

(:~
 : Prepare OAS3 Operation Object.
 : @see https://swagger.io/specification/#operationObject
 :)
declare %private function openapi:operation-object($function as element(function))
as map(*) {
  let $desc := normalize-space($function/description)
  let $see := normalize-space($function/see)
  let $deprecated := $function/deprecated
  let $tags := array { $function/@name => substring-before(":") }
  return
  map{
    $function/annotation[@name eq "rest:path"]/replace(value, "\{\$", "{") :
    for $method in $function/annotation[@name = $openapi:supported-methods]/substring-after(lower-case(@name), "rest:")
    return
    map{
      $method:
      map:merge((
        map{ "description": $desc},
        map{ "tags": $tags},
        $see[1] ! map{"externalDocs": $see ! map{
          "url": .,
          "description": "the official documentation by the maintainer or a thrid-party documentation"}},
        $deprecated ! map{"deprecated": true()},
        openapi:parameter-object($function),
        openapi:responses-object($function),
        openapi:requestBody-object($function)
      ))
    }
  }
};

declare %private function openapi:requestBody-object($function as element(function))
as map(*)? {
if(not(exists($function/annotation[@name = ("rest:POST", "rest:PUT")]/value))) then () else
    let $name := replace($function/annotation[@name = ("rest:POST", "rest:PUT")]/value, "\{|\}|\$", "")
    let $desc := string($function/argument[@var eq $name])
    let $example := string(($function/annotation[@name="test:arg"][value[1] eq $name])[1]/value[2])
    return
    map{
        "requestBody":  map{
            "description": "Value to process as variable: $" || $name,
            "content": map{
                "application/xml": map{
                    "examples": map{
                        $name: map{
                            "summary": $desc,
                            "value": serialize($example)
                        }
                    }
                }
            },
            "required": true()
        }
    }
};

(:~
 : Prepare OAS3 Response Object.
 : @see https://swagger.io/specification/#responsesObject
 :  :)
declare %private function openapi:responses-object($function as element(function))
as map(*){
  map{
    "responses":
    map{
      "200": map{
        "description": string($function/returns),
        "content": openapi:mediaType-object($function)
      }
    }
 }
};

(:~
 : Prepare OAS3 Parameter Object.
 : @see https://swagger.io/specification/#mediaTypeObject
 :  :)
declare %private function openapi:parameter-object($function as element(function))
as map(*) {
    map{
      "parameters": array{
          openapi:parameters-path($function),
          openapi:parameters-query($function)
      }
    }
};

(:~
 : Prepares all PATH parameters for a given function
 : @param $function A function element from the inspect module
 : :)
declare %private function openapi:parameters-path($function as element(function))
as map(*)* {
    let $pathParameters :=
        $function/annotation[@name = "rest:path"][1]
            /tokenize(value, "\{")
            [starts-with(., "$")]
            ! (.
                => substring-after("$")
                => substring-before("}")
            )

    for $parameter in $pathParameters
    let $name := replace($parameter, "\{|\$|\}", "")
    let $argument := $function/argument[@var eq $name]
    let $basics := map:merge((
                map{
                    "name": $name,
                    "in": "path",
                    "required": true()},
                    openapi:schema-object($argument)
    ))
    let $description := $function/argument[@var = $name]/text() ! map{ "description": .}
    let $example := openapi:example($function, $name)
    return
        map:merge(($basics, $description, $example))

};

(:~
 : Prepares all QUERY parameters for a given function
 : @param $function A function element from the inspect module
 : :)
declare %private function openapi:parameters-query($function as element(function))
as map(*)* {
    let $queryParameters := $function/annotation[@name = "rest:query-param"]
    for $parameter in $queryParameters
    let $name := string($parameter/value[2]) => replace("\{|\$|\}", "")
    let $argument := $function/argument[@var eq $name]
    let $required := exists($parameter/value[3] and not(contains($argument/@cardinality, "zero")))
    let $basics :=
            map:merge((
                map{
                    "name": $name,
                    "in": "query",
                    "required": $required
                    },
                    openapi:schema-object($argument)
                ))
    let $description := $function/argument[@var = $name]/text() ! map{ "description": .}
    let $pos := index-of(($function/argument/string(@var)), $name)
    let $example := openapi:example($function, $name)
    return
        map:merge(($basics, $description, $example))
};

(:~
 : Prepare OAS3 Media Type Object.
 : @see https://swagger.io/specification/#mediaTypeObject
 :  :)
declare %private function openapi:mediaType-object($function)
as map(*) {
  let $produces := (
        string($function/annotation[@name="rest:produces"]),
        string($function/annotation[@name="output:media-type"]),
        string($function/annotation[@name="output:method"]/openapi:method-mediaType(string(.))),
        "application/xml"
      )
  return
    map{
      $produces[. != ""][1]: openapi:schema-object($function/returns)
    }
};

(:~
 : Prepare OAS3 Schema Object.
 : @param $returns A element from the inspect-module() function,
 : either *:returns or *:argument
 : @see https://swagger.io/specification/#mediaTypeObject
 :  :)
declare %private function openapi:schema-object($returns as element(*))
as map(*) {
  map{"schema":
    map:merge((
        map{
          "type": "string",
          "x-xml-type": string($returns/@type)
        },
        if(contains($returns/@cardinality, "zero")) then map{ "nullable": true() } else ()
    ))
  }
};

declare %private function openapi:tags-object($modules as element(module)+)
as map(*) {
  map{
    "tags": array{
        for $module in $modules
        return
            map{
                "name": string($module/@prefix),
                "description": normalize-space($module/description)
            }
        }
  }
};

(:~
 : Resolve an SPDX licenseId
 : @param a valid SPDX license code
 : @return a map with all SPDX data to the requested license
 :)
declare function openapi:spdx($licenseId as xs:string)
as map(*) {
let $collection-uri := /id("restxqopenapi")/base-uri()
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
declare %private function openapi:method-mediaType($method as xs:string?)
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
declare %private function openapi:example($function as element(function), $name as xs:string)
as map(*)* {
    string($function/annotation[@name = "test:arg"][value[1] = $name]/value[2])
    ! map{ "example": .}
};
