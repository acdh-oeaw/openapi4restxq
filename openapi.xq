xquery version "3.1";

(: when using the library in other module the location part («at») SHOULD be
ommited as the library registers its namespace to eXist. :)
import module namespace openapi="https://lab.sub.uni-goettingen.de/restxqopenapi"
  at "content/openapi.xqm";

(: prepare a json document on HTTP requests :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";

(: we register the REST interface :)
let $prepare := xmldb:get-child-resources("/db/apps/openapi/content")[. != "openapi.xqm"]
    ! exrest:register-module(xs:anyURI("/db/apps/openapi/content/" || .))

return

(: prepare OpenAPI as map(*) :)
openapi:main("/db/apps/openapi")

(: ("paths")("/openapi-test/full/get/{param1}/{param2}.{format}") :)
