# OpenAPI
OpenAPI (formerly swagger) is a standard for REST-API documentation and so
optimized to describe standardized communication with HTTP.

# RESTXQ
[RESTXQ](http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html)
is the implementation of well-known function annotations in [XQuery](https://www.w3.org/TR/xquery-31/).

# OpenAPI for RESTXQ
This software combines the power of function annotation in XQuery to prepare an
OpenAPI conform documentation. It covers the RESTXQ annotations as well as the
[XQSuite](http://exist-db.org/exist/apps/doc/xqsuite.xml) annotations and uses
[xqDocs](http://xqdoc.org/xqdoc_comments_doc.html) for describing the API.

It is meant to be used for a single [expath package](http://expath.org/spec/pkg)
and written for [eXist-db](http://exist-db.org).

## Build
For preparing the `openapi.json` the application is build with
```
ant
```

If you want to use swagger-ui (a ready-to-use documentation in HTML) you have to
load the swagger-ui package before:
```bash
npm install && ant
```

## Install
Install the build target (xar package) to a recent eXist-db by either placing
the file in the `autodeploy` directory or using the package manager application
installed by default at a running database.

## Use
### Integrated in own applications
By adding the following lines to the `controller.xql` a path like
[/myApplication/openapi/index.html](http://localhost:8080/exist/apps/myApplication/openapi/index.html)
will become available. (The usage of the pipe operator requires XQuery version 3.1.)
```xq
else if (starts-with($exist:path, "/openapi/")) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward
      url="/openapi/{ $exist:path => substring-after("/openapi/") => replace("json", "xq") }"
      method="get">
      <add-parameter name="target" value="{ substring-after($exist:root, "://") || $exist:controller }"/>
      <add-parameter name="register" value="false"/>
    </forward>
  </dispatch>
```

### Standalone
By default the application provides a preview and a few simple REST paths as test
interfaces. Open the application via the Dashboard or browse to [http://localhost:8080/exist/apps/openapi/index.html](http://localhost:8080/exist/apps/openapi/index.html).

To view the documentation for other packages, use the input filed in the top bar
to ask for a description file at `openapi.json?target=/db/apps/myApplication`.
Optional the re-registration of functions to the RESTXQ engine is possible via
an additional parameter: `&register=true`.

## Configure
To include information not present in one of the parsed documents, the library
checks the availability of a resources named `openapi-config.xml` in the
root collection of the application where to create the description file for.
It is recommended to place a customized copy of the file provided with this
package.

## Develop
To start developing or testing the package a ant target is available that sets
up the environment.
```bash
ant test && bash test/eXist-db-*/bin/startup.sh
```

Behind the curtain the information will be collected by calling
```xq
inspect:inspect-module(xs:anyURI("/db/apps/openapi/content/openapi-tests-full.xqm"))
```

## Limitations
### combining path and query parameters
Query parameters passed by `%rest:query-param()` MUST use a name different from
path parameter variable names. Since the parameter name can be defined different
from the variable name via this function, it is REQUIRED to use different path
variable name and query parameter names. It is CONSIDERED to be best practice
that both – name and var name – SHOULD not interfere or have any cross-realation
by their names.

### Example values
Example values are taken from the `%test:arg()` annotation and the usage of
`%test:args()` is not supported.

# Credits
There is no relation between the author of this software and the named companies,
initiatives, products, specifications and trademarks.

This software is written to comply with the OpenAPI Specifications (OAS) and
provides an implementation for RESTXQ. It is tested with eXist-db eXclusively.

Usage of the [OpenAPI Logo](icon.png) is in accordance to the guidelines
provided at [openapis.org/faq](https://www.openapis.org/faq). In this case it is
used to appear on eXist-db dashboard screen when this application is installed.

OAS and OpenAPI Specification and their respective logos, are trademarks of The
Linux Foundation. Linux is a registered trademark of Linus Torvalds.

# Thank You, Open Source!
