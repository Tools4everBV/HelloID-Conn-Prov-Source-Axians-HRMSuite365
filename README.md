# HelloID-Conn-Prov-Source-Axians-HRMSuite365

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible for acquiring connection details such as username, password, certificate, and endpoint information. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://github.com/Tools4everBV/HelloID-Conn-Prov-Source-Axians-HRMSuite365/blob/main/Logo.png?raw=true">
</p>

## Table of contents

- [HelloID-Conn-Prov-Source-Axians-HRMSuite365](#helloid-conn-prov-source-axians-hrmsuite365)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
    - [SOAP pages](#soap-pages)
  - [Getting started](#getting-started)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
      - [Logic in-depth](#logic-in-depth)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Source-Axians-HRMSuite365_ is a _source_ connector for importing Axians HRMSuite365 persons and their employment and formation contracts into HelloID. Axians HRMSuite365 exposes the data through a SOAP web service. The connector calls the `FuncGetPageData` action and translates Axians HRMSuite365 field numbers into readable property names.

### SOAP pages

The following Axians HRMSuite365 pages are used by the connector:

| Page name    | Description               |
| ------------ | ------------------------- |
| `EXT_WERK`   | Person data               |
| `EXT_PART`   | Partner data              |
| `EXT_DVB`    | Employment data           |
| `EXT_FORM`   | Formation data            |
| `EXT_COMP_W` | Person component data     |
| `EXT_COMP`   | Employment component data |

## Getting started

### Connection settings

The following settings are required to connect to the web service and determine which contracts are imported.

| Setting          | Description                                                            | Mandatory |
| ---------------- | ---------------------------------------------------------------------- | --------- |
| `UserName`       | The username used to connect to the Axians HRMSuite365 web service.    | Yes       |
| `Password`       | The password used to connect to the Axians HRMSuite365 web service.    | Yes       |
| `BaseUrl`        | The URL of the Axians HRMSuite365 SOAP web service.                    | Yes       |
| `HistoricalDays` | The number of days in the past from which contracts are imported.      | Yes       |
| `FutureDays`     | The number of days in the future through which contracts are imported. | Yes       |

The default values for `HistoricalDays` and `FutureDays` are `90` days.

### Prerequisites

- A HelloID agent server.
- The connector was tested with the `Kidsvision` application, which handles authentication. This application only supports `NTLM`, so the connector requires a Windows-based HelloID agent (The HelloID cloud agent is not Windows-based).
- An Axians HRMSuite365 account with the permissions required to access the configured SOAP web service pages.

### Remarks

#### Logic in-depth

- The web service returns numeric field identifiers. The translation mappings at the top of `persons.ps1` convert these identifiers into readable property names. These mappings can differ between Axians HRMSuite365 customers and may require adjustment.
- Person, partner, employment, and formation records are retrieved separately and combined by the person external ID.
- Employment and formation records are filtered using `HistoricalDays` and `FutureDays`. Persons without an employment in the selected period are skipped.
- Employment and formation records are exported as HelloID contracts. Employment contracts use the employment number as their contract external ID; formation contract IDs combine the formation external ID, function code, and sequence.
- For each component field, the connector selects the latest component whose start date is today or earlier. If no such component exists, it selects the earliest future component.

## Setup the connector

> [Setup HelloID Source Connector](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system)

## Getting help

> For more information on how to configure a HelloID PowerShell connector, refer to the [HelloID documentation](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system).

## HelloID docs

The official HelloID documentation can be found at [https://docs.helloid.com/](https://docs.helloid.com/).
