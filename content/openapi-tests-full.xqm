(:~
 : complex TESTMODULE for OpenAPI from RESTXQ.
 : This is module number two.
 : It provides more complex APIs.
 :   :)
xquery version "3.1";

module namespace openapi-test-full="https://lab.sub.uni-goettingen.de/restxqopenapi/test2";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";


(:~
 : A more complex example with parameters in path and query in the request body.
 : @param $paramPath A path paramter for your pleasure.
 : @param $int Yet another path parametet. good.
 : @param $format We specify the format by a classical file ending: preceded by a dot.
 : @param $getParam Additional filter (string)
 : @param $body an xml fragment to parse
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:POST("{$body}")
%rest:consumes("application/xml", "text/xml")
%rest:path("/openapi-test/full/post/{$paramPath}/{$int}.{$format}")
%rest:query-param("getParam", "{$getParam}", "2019")

%rest:produces("application/json")

%output:method("json")

%test:arg("paramPath", "here")
%test:arg("int", "123")
%test:arg("getParam", "and-get")
function openapi-test-full:post(
    $paramPath as xs:string,
    $int as xs:int,
    $format as xs:string,
    $getParam as xs:string+,
    $body as item()?)
as element(test) {
    <test>
        <parameters n="6">
            <path>{ $paramPath }</path>
            <int>{ $int }</int>
            <format>{ $format }</format>
            <get1>{ $getParam }</get1>
            <body>{ $body }</body>
        </parameters>
        <response n="1" type="application/json"/>
    </test>
};
