(:~
 : TESTMODULE for OpenAPI from RESTXQ.
 : This is number one.
 :   :)
xquery version "3.1";

module namespace openapi-test-simple="https://lab.sub.uni-goettingen.de/restxqopenapi/test1";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace test="http://exist-db.org/xquery/xqsuite";

(:~
 : Simple GET Method Test for OpenAPI
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:GET
%rest:path("/openapi-test/simple/get")
function openapi-test-simple:get()
as element(test) {
    <test>
        <parameters n="0"/>
        <response n="1" type="application/xml"/>
    </test>
};

(:~
 : Simple GET Method Test with HEADER parameter for OpenAPI
 : @param $test A string added to the request header “x-test”
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:GET
%rest:path("/openapi-test/simple/get-header")
%rest:header-param("x-test", "{$test}")
function openapi-test-simple:get-header($test as xs:string*)
as element(test) {
    <test>
        <parameters n="1">
            <header>{ $test }</header>
        </parameters>
        <response n="1" type="application/xml"/>
    </test>
};

(:~
 : Simple GET Method Test with COOKIE parameter for OpenAPI
 : @param $test A string added to the request header “x-test”
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:GET
%rest:path("/openapi-test/simple/get-cookie")
%rest:cookie-param("tasty_cookie", "{$test}")
function openapi-test-simple:get-cookie($test as xs:string*)
as element(test) {
    <test>
        <parameters n="1">
            <cookie>{ $test }</cookie>
        </parameters>
        <response n="1" type="application/xml"/>
    </test>
};

(:~
 : Simple GET Method Test with multiple parameter for OpenAPI
 : @param $test A string added to the request header “x-test”
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:GET
%rest:path("/openapi-test/simple/get-multi")
%rest:query-param("getTest1", "{$getTest1}")
%rest:query-param("getTest2", "{$getTest2}")
%rest:cookie-param("tasty_cookie", "{$cookieTest}")
%rest:header-param("x-test", "{$headerTest}")
function openapi-test-simple:get-cookie($getTest1 as xs:string*, $getTest2 as xs:string*, $cookieTest as xs:string*, $headerTest as xs:string*)
as element(test) {
    <test>
        <parameters n="4">
            <header>{ $headerTest }</header>
            <cookie>{ $cookieTest }</cookie>
            <get1>{ $getTest1 }</get1>
            <get2>{ $getTest2 }</get2>
        </parameters>
        <response n="1" type="application/xml"/>
    </test>
};


(:~
 : Simple but deprecated GET Method Test for OpenAPI
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 : @deprecated
 :)
declare
%rest:GET
%rest:path("/openapi-test/simple/get-deprecated")
function openapi-test-simple:get-deprecated()
as element(test) {
    <test>
        <deprecated/>
        <parameters n="0"/>
        <response n="1" type="application/xml"/>
    </test>
};

(:~
 : Simple PUT Method Test for OpenAPI
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:PUT
%rest:path("/openapi-test/simple/put")
function openapi-test-simple:put()
as element(test) {
    <test>
        <parameters n="0"/>
        <response n="1" type="application/xml"/>
    </test>
};

(:~
 : Simple DELETE Method Test for OpenAPI
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:DELETE
%rest:path("/openapi-test/simple/del")
function openapi-test-simple:del()
as element(test) {
    <test>
        <parameters n="0"/>
        <response n="1" type="application/xml"/>
    </test>
};

(:~
 : Simple DELETE Method Test for OpenAPI
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:POST
%rest:path("/openapi-test/simple/post")
function openapi-test-simple:post()
as element(test) {
    <test>
        <parameters n="0"/>
        <response n="1" type="application/xml"/>
    </test>
};

(:~
 : Simple HEAD Method Test for OpenAPI
 : @return empty as defined by HTTP
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:HEAD
%rest:path("/openapi-test/simple/head")
function openapi-test-simple:head()
as empty-sequence() {()};

(:~
 : All Methods Test for OpenAPI
 : @return empty
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:GET
%rest:HEAD
%rest:POST
%rest:PUT
%rest:DELETE
%rest:path("/openapi-test/simple/multi")
function openapi-test-simple:multi-methods(){
    ()
};

(:~
 : GET Method with a path defined also for a POST in a different function
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
  %rest:GET
  %rest:path("/openapi-test/simple/multi-function")
function openapi-test-simple:multi-get()
as element(test) {
    <test>
        <parameters n="0"/>
        <response n="1" type="application/xml"/>
    </test>
};


(:~
 : POST Method with a path defined also for a POST in a different function
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:POST("{$body}")
%rest:path("/openapi-test/simple/multi-function")
function openapi-test-simple:multi-post($body)
as element(test) {
    <test>
        <parameters n="0"/>
        <response n="1" type="application/xml"/>
    </test>
};

(:~
 : POST Method with a path defined also for a POST in a different module
 : @return xml fragment that describes request and response
 : @see http://example.com/documentation/about/this
 :)
declare
%rest:POST("{$body}")
%rest:path("/openapi-test/simple/multi-module")
function openapi-test-simple:multi-post($body)
as element(test) {
    <test>
        <parameters n="0"/>
        <response n="1" type="application/xml"/>
    </test>
};
