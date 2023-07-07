xquery version "3.1";
module namespace _ = "https://lab.sub.uni-goettingen.de/restxqopenapi/swagger-ui";
import module namespace openapi = "https://lab.sub.uni-goettingen.de/restxqopenapi" at "content/openapi.xqm";
import module namespace request = "http://exquery.org/ns/request";
import module namespace l = "http://basex.org/modules/admin";

import module namespace rest = "http://exquery.org/ns/restxq";

declare
  %rest:path("openapi/openapi.json")
  %rest:query-param("target", "{$target}")
function _:openapi-file($target as xs:string?) {
    let $json := openapi:json(if (exists($target)) then $target else file:base-dir())
    return _:return-content($json, 'application/json')  
};

declare function _:get-base-uri-public() as xs:string {
    let $forwarded-hostname := if (contains(request:header('X-Forwarded-Host'), ',')) 
                                 then substring-before(request:header('X-Forwarded-Host'), ',')
                                 else request:header('X-Forwarded-Host'),
        $urlScheme := if ((lower-case(request:header('X-Forwarded-Proto')) = 'https') or 
                          (lower-case(request:header('Front-End-Https')) = 'on')) then 'https' else 'http',
        $port := if ($urlScheme eq 'http' and request:port() ne 80) then ':'||request:port()
                 else if ($urlScheme eq 'https' and not(request:port() eq 80 or request:port() eq 443)) then ':'||request:port()
                 else '',
        (: FIXME: this is to naive. Works for ProxyPass / to /exist/apps/cr-xq-mets/project
           but probably not for /x/y/z/ to /exist/apps/cr-xq-mets/project. Especially check the get module. :)
        $xForwardBasedPath := (request:header('X-Forwarded-Request-Uri'), request:path())[1]
    return $urlScheme||'://'||($forwarded-hostname, request:hostname())[1]||$port||$xForwardBasedPath
};

(:~
 : Returns a html or related file.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("openapi/{$file=[^/]+}")
function _:file($file as xs:string) as item()+ {
  let $path := _:base-dir()||$file
  return if (file:exists($path)) then
    if (matches($file, '\.(htm|html|js|map|css|png|gif|jpg|jpeg|ico|woff|woff2|ttf)$', 'i')) then
    _:return-content(file:read-binary($path), web:content-type($path)) else _:forbidden-file($file)
  else
  (
    web:response-header(map{'media-type': 'text/html',
                            'method': 'html'}, 
                        map{'Content-Language': 'en',
                        'X-UA-Compatible': 'IE=11'},
                        map{'status': 404, 'message':$file||' was not found'}),
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$file||' was not found'}</title>
    <body>        
       <h1>{$file||' was not found'}</h1>
    </body>
  </html>
  )
};

declare %private function _:return-content($bin, $media-type as xs:string) {
  let $hash := xs:string(xs:hexBinary(hash:md5($bin)))
       , $hashBrowser := request:header('If-None-Match', '')
    return if ($hash = $hashBrowser) then
      web:response-header(map{}, map{}, map{'status': 304, 'message': 'Not Modified'})
    else (
      web:response-header(map { 'media-type': $media-type,
                                'method': 'basex',
                                'binary': 'yes' }, 
                          map { 'X-UA-Compatible': 'IE=11'
                              , 'Cache-Control': 'max-age=3600,public'
                              , 'ETag': $hash }),
      $bin
    )
};

declare %private function _:base-dir() as xs:string {
  file:base-dir()||'resources/swagger-ui-dist/'
};

(:~
 : Returns index.html on /.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("openapi")
function _:index-file() as item()+ {
  let $index-html := _:base-dir()||'index.html',
      $uri := rest:uri(),
(:      $log := l:write-log('api:index-file() $uri := '||$uri||' base-uri-public := '||api:get-base-uri-public(), 'DEBUG'),:)
      $absolute-prefix := if (matches(_:get-base-uri-public(), '/$')) then () else _:get-base-uri-public()||'/'
  return if (exists($absolute-prefix)) then
    <rest:response>
      <http:response status="302">
        <http:header name="Location" value="{$absolute-prefix}"/>
      </http:response>
    </rest:response>
  else if (file:exists($index-html)) then
    <rest:forward>index.html</rest:forward>
  else _:forbidden-file($index-html)    
};

(:~
 : Return 403 on all other (forbidden files).
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %private
function _:forbidden-file($file as xs:string) as item()+ {
  <rest:response>
    <http:response status="403" message="{$file} forbidden.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$file||' forbidden'}</title>
    <body>        
       <h1>{$file||' forbidden'}</h1>
    </body>
  </html>
};

declare
  %rest:path("openapi/runtime")
function _:runtime-info() as item()+ {
  let $runtime-info := db:system(),
      $xslt-runtime-info := xslt:transform(<_/>,
      <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="xml"/><xsl:template match='/'><_><product-name><xsl:value-of select="system-property('xsl:product-name')"/></product-name><product-version><xsl:value-of select="system-property('xsl:product-version')"/></product-version></_></xsl:template></xsl:stylesheet>)/*
  return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>Runtime info</title>
    <body>        
       <h1>Runtime info</h1>
       <table>
       {for $item in $runtime-info/*:generalinformation/*
       return
         <tr>
           <td>{$item/local-name()}</td>
           <td>{$item}</td>
         </tr>
       }
         <tr>
           <td>{$xslt-runtime-info/*:product-name/text()}</td>
           <td>{$xslt-runtime-info/*:product-version/text()}</td>
         </tr>
       </table>
    </body>
  </html>
};