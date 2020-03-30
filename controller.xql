xquery version "3.1";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

else if ($exist:path eq "/") then
    (: redirect root path to index.html :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="resources/swagger-ui-dist/index.html"/>
    </dispatch>

else if($exist:path eq "/openapi.json" and $exist:resource eq "openapi.json") then
    (: forward to openapi.xq :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="openapi.xq" />
    </dispatch>

else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
