# OpenAPI

[![pipeline status](https://gitlab.com/acdh-oeaw/openapi4restxq/badges/master_basex/pipeline.svg)](https://gitlab.com/acdh-oeaw/openapi4restxq/commits/master_basex)

OpenAPI (formerly swagger) is a standard for REST-API documentation and so
optimized to describe standardized communication with HTTP.

## RESTXQ

[RESTXQ](http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html)
is the implementation of well-known function annotations in [XQuery](https://www.w3.org/TR/xquery-31/).

## OpenAPI for RESTXQ

This is a BaseX port of the original [exist-db version](https://gitlab.gwdg.de/subugoe/openapi4restxq).

This software combines the power of function annotation in XQuery to prepare an
OpenAPI conform documentation. It covers the RESTXQ annotations as well as the
[XQSuite](http://exist-db.org/exist/apps/doc/xqsuite.xml) annotations and uses
[xqDocs](http://xqdoc.org/xqdoc_comments_doc.html) for describing the API.
(Note that this does not mean XQSuite works in BaseX. That would need to be ported separately.)

You can use your own annotation namespace for :args, :assertEquals, :consumes and :produces if you
see unwanted side effects. %test has no meaning out of the box for BaseX.

It is meant to be cloned into a `webapp` RESTXQ directory of a [BaseX](http://basex.org)
setup. `content/openapi.xqm` is a self contained module that can be copied into your project's directory.

## Build

If you want to use swagger-ui (a ready-to-use documentation in HTML) you have to
load the swagger-ui package before:

```bash
yarn install
```

## Install

If you have the contents of this repository in your RESTXQ path (`webapp` by default) you have access to
swagger-ui using the `/openapi` URL.

## Use

### Integrated in own applications

You need some info XML files:

* `expath-pkg.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://expath.org/ns/pkg"
  name="urn:yourproject"
  abbrev="yourproj"
  version="0.3.0"
  spec="1.0"
  xml:id="yourprojid">
  <title>Project title</title>
  <dependency processor="http://basex.org" semver-min="9.2"/>
  <xquery>
    <namespace>urn:yourproject</namespace>
    <file>yourmodule.xqm</file>
  </xquery>
</package>
```

* `openapi-config.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<config xmlns="https://lab.sub.uni-goettingen.de/restxqopenapi">
  <info>
  <termsOfService>https://example.com/terms-of-use</termsOfService>
  <contact>
      <email>info@example.com</email>
  </contact>
  </info>
  <servers>
    <server url="http://localhost:8984/">Local development server</server>
    <server url="https://example.com/">Production server</server>
  </servers>
  <tags>
    <tag name="category1" method="exclusive">
        You can sort your functions into categories using these tags here.
        <function name="yourproj:func1"/>
        <function name="yourproj:func2"/>
    </tag>
    <tag name="category" method="exclusive">
        Another category
        <function name="yourproj:func3"/>
    </tag>
  </tags>
  <!-- if you have any authentication: httpBasic info generation is implemented at the moment: >
  <components>
    <securitySchemes>
      <securityScheme name="httpBasic">
        This service uses HTTP Basic authentication.
        <type>http</type>
        <scheme>basic</scheme>
      </securityScheme>
    </securitySchemes>
  </components>
  <security>
    <SecurityRequirement name="httpBasic"/>
  </security> <!- -->
</config>
```

* You can either put the contents of this repository in your RESTXQ directory and have the swagger-ui ready
  and load `openapi.xqm` from `openapi4restxq/content/openapi.xqm`
* or you copy `content/openapi.xqm`, `openapi-config.xml` and `spdx-licenses.json` for example into `3rd-party/openapi`.
  These files represent the XQuery code and some default configuration needed.

You then add a invocation like this (adjust the `at "3rd-party/content/openapi.xqm"` if you don't copy `openapi.xqm`)

```xq
import module namespace openapi="https://lab.sub.uni-goettingen.de/restxqopenapi" at "3rd-party/content/openapi.xqm";
[...]
declare
    %rest:path('/yourrestproject/openapi.json')
    %rest:produces('application/json')
    %output:media-type('application/json')
function yourrestproject:getOpenapiJSON() as item()+ {
  openapi:json(file:base-dir())
};
```

This makes a json representation of your annotated and documented API avaialable.

You can load this in swagger-ui if you type `/yourrestproject/openapi.json` into the default explore input box.
If you want to configure [swagger-ui's start parameters](https://github.com/swagger-api/swagger-ui/blob/master/docs/usage/configuration.md) have a look at the documentation.
For example to have just a predefined set of openapi specifications available try the following code in `openapi4restxq/resources/swagger-ui-dist/index.html`:

```javascript
    window.onload = function() {
      // Begin Swagger UI call region
      const ui = SwaggerUIBundle({
        urls: [
          { url: "/yourrestproject/openapi.json", name: "my rest API"},
          { url: "https://petstore.swagger.io/v2/swagger.json", name: "petstore example API"}
        ],
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        plugins: [
          SwaggerUIBundle.plugins.DownloadUrl
        ],
        layout: "StandaloneLayout"
      })
      // End Swagger UI call region

      window.ui = ui
    }
```

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

To start developing or testing the package just change `openapi.xqm`

Behind the curtain the information will be collected by calling

```xq
inspect:module("/basex/webapp/yourproject/yourmodule.xqm")
```

Note that `inspect:module` and its exist-db counterpart generate comapreable but
different XML.

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

## Credits

* swagger.io for swagger-ui
* Mathias Goebel for the [exist-db version of this tool](https://gitlab.gwdg.de/subugoe/openapi4restxq)

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
