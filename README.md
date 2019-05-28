# OpenAPI
OpenAPI (formerly swagger) is a standard for REST-API documentation and so
optimized to describe standardized communication with HTTP.

# RESTXQ
[RESTXQ](http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html)
is the implementation of well-known function annotations in [XQuery](https://www.w3.org/TR/xquery-31/).

# OpenAPI for RESTXQ
This is a BaseX port of the original exist-db version.

This software combines the power of function annotation in XQuery to prepare an
OpenAPI conform documentation. It covers the RESTXQ annotations as well as the
[XQSuite](http://exist-db.org/exist/apps/doc/xqsuite.xml) annotations and uses
[xqDocs](http://xqdoc.org/xqdoc_comments_doc.html) for describing the API.

It is meant to be used for a single [expath package](http://expath.org/spec/pkg)
and written for [BaseX](http://basex.org).

## Build
TODO (or nothing)

If you want to use swagger-ui (a ready-to-use documentation in HTML) you have to
load the swagger-ui package before:
```bash
yarn install
```

## Install
TODO

## Use
### Integrated in own applications
By TODO a path like
[/myApplication/openapi/index.html](http://localhost:8984/myApplication/openapi/index.html)
will become available. (The usage of the pipe operator requires XQuery version 3.1.)


### Standalone
By default the application provides a preview and a few simple REST paths as test
interfaces. Open the application via the Dashboard or browse to [http://localhost:8984/openapi/index.html](http://localhost:8984/openapi/index.html).

Change the the input filed in the top bar to `openapi.json`.

To view the documentation for other packages, use the input filed in the top bar
to ask for a description file at `openapi.json?target=Q:\BaseX9\webapp\myApplication\`.

## Configure
To include information not present in one of the parsed documents, the library
checks the availability of a resources named `openapi-config.xml` in the
root collection of the application where to create the description file for.
It is recommended to place a customized copy of the file provided with this
package.

## Develop
To start developing or testing the package TODO

Behind the curtain the information will be collected by calling
```xq
inspect:module("/basex/webapp/openapi/content/openapi-tests-full.xqm")
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
