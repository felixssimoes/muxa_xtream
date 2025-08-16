# Improvement Plan

This document outlines a plan for improving the `muxa_xtream` codebase. The tasks are ordered to be worked on sequentially.

## Phase 1: Refactoring and Code Quality

- [x] **1. Centralize HTTP Request Logic:**
  - [x] Create a private `_sendRequest` helper method in `lib/src/client.dart` to encapsulate common HTTP request logic (URL building, logging, request creation, sending, and response handling).
  - [x] Refactor `getUserAndServerInfo`, `_getAction`, `ping`, `getM3u`, and `getXmltv` to use the new `_sendRequest` method.

- [x] **2. Simplify `getShortEpg` Retry Logic:**
  - [x] Refactor the `getShortEpg` method in `lib/src/client.dart` to make the retry logic for `streamId` and `epgChannelId` more linear and easier to read.

- [x] **3. Improve `capabilities` Error Handling:**
  - [x] Modify the `capabilities` method in `lib/src/client.dart` to log any caught errors before returning the default `XtCapabilities` object.

## Phase 2: Advanced Improvements

- [x] **4. Streamline `getM3u` and `getXmltv`:**
  - [x] Modify the `XtHttpAdapter` interface to expose the response body as a `Stream<List<int>>`.
  - [x] Update the `getM3u` and `getXmltv` methods to stream the response body directly to the respective parsers, removing the need for `async*` and improving memory efficiency.
