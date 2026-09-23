# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [2.0.0] - 23-09-2026

Renamed from _HelloID-Conn-Prov-Source-Mercash_ to _HelloID-Conn-Prov-Source-Axians-HRMSuite365_.

### Added

- Added configurable `HistoricalDays` and `FutureDays` settings, both with a default value of `90` days.
- Added support for the `EXT_FORM`, `EXT_COMP_W`, and `EXT_COMP` SOAP pages.
- Added formation contracts and component data to the HelloID output.
- Added date-based filtering for employment and formation records.
- Added selection of the latest active component, or the earliest future component when no active component exists.
- Added structured handling of HTTP and web service errors.

### Changed

- Replaced the web service proxy implementation with explicit SOAP requests using `Invoke-RestMethod`.
- Expanded and renamed field mappings to provide readable Axians HRMSuite365 property names.
- Partner, employment, formation, and component data are now combined per person.
- Employment and formation records are exported as HelloID contracts with type codes and contract external IDs.
- Persons are exported individually as JSON objects.

### Removed

- Removed the `ParMenu` and `ProxyAddress` configuration settings.

## [1.0.0] - 16-12-2021

This is the first official release of _HelloID-Conn-Prov-Source-Mercash_.