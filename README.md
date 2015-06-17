# VIVO Snapshot tool

## Purpose
- Detect whether changes to the code have resulted in any changes to the pages that are served.
- Test a small “canary set” to detect obvious problems. When the obvious problems are fixed, enlarge the set and 
repeat until the entire site is tested. Or simply test the entire set to begin with.

## Use cases
- We should be able to specify the set of expected changes, so we could compare two datasets using different sets of criteria.
- We need to record the set of differences, so we can review them at leisure.
- Once we have found two differing results, we want to re-compare them using different sets of expected changes, 
in order to develop our sets.

## Approach
A group of commands that will allow you to:
- Create a list of interesting URIs from a VIVO instance.
- Create lists of requests that will be run against that VIVO instance.
- Authorize a VIVO account to be a proxy self-editor on a list of individuals.
- Capture a snapsnot of the VIVO instance, in the form of the responses that come from a list of requests.
- Compare two snapshots, allowing for some expected changes, and producing a list of the unexpected changes.

## Structures

## URI List
- Just a list of URIs, one per line.

### Session List
- At its simplest form, a list of URLs which can be used for a snapshot.
- More precisely, a list of requests, one per line: 
in addition to the URL, each request may specify POST or GET, HTTP headers, and parameters. 
- Each line in the file can actually constitute a session, with an optional login/logout, and multiple requests.

## Commands

```
vivosnap prepare uri-list [classlist_file] [VIVO_homepage_URL] [uri_list_file]
```
Create a list of URIs. You provide a file with class URIs, and a URL for VIVO. 
The tool will make requests of VIVOs ListRDF API, and write the results to the URI list file.

```
vivosnap prepare session-list [uri_list_file] [account_email] [account_password] [session_list_file]
```
Create a session list. 
You provide a file of URIs, and the tool will generate the URLs needed to fetch the profile pages for those URIs.
If you want a login on each session, provide the email address and password of the desired login account.

```
vivosnap prepare self-editor-account [VIVO_homepage_URL] [uri_list_file] [admin_email] [admin_password] [editor_email] [editor_password]
```
Write triples to the user accounts model of the VIVO to create the self-editor-account (unless it exists already) 
and to make it a proxy editor for all of the URLs in the list.

```
vivosnap prepare sub-list [session_list_file] [count] [sub_list_file]
```
Create a smaller session list from an existing one. 
The new list will have the specified number of entries, extracted at even intervals from the existing list.

```
vivosnap capture [VIVO_homepage_URL] [session_list_file] [responses_directory] {OVERWRITE|REPLACE}
```
Capture a snapshot. Provide the URL of the VIVO home page, and a session list, and the tool will
make the requests, storing the responses in the given directory. 
If the responses directory does not exist, it will be created, providing its parent directory exists.
If the responses directory is not empty, you must specify either OVERWRITE or REPLACE. 
- OVERWRITE creates new responses, writing over existing ones as appropriate.
- REPLACE deletes the contents of the directory before running.

```
vivosnap compare [reference_responses_directory] [test_responses_directory] {expected_changes_file} [differences_directory]
```
Compare two snapshots. 
The test snapshot is expected to be a subset of the reference snapshot (or equivalent), taken at a later time.
The list of expected changes, if present, will be applied when comparing responses.
The differences between the snapshots will be stored in the given directory.

```
vivosnap re-compare [differences_directory] [expected_changes_file] [new_differences_directory]
```
Re-compare just the differences between two snapshots, presumably with a different list of expected changes.
The original snapshot directories must still exist, because the differences directory will reference them.

## Data structure details

### Session list
Here is a silly pseudo-syntax. URLs are all relative to the VIVO home page.
```
line ⇔ session
session ⇔ [login ==> ] request [ ==> request ]*
login ⇔ LOGIN email pass
request ⇔ url [method | header | parameter]*
method ⇔ GET | POST
header ⇔ key(value)
parameter ⇔ key=value
value ⇔ must be in single quotes if contains space
```

#### Examples
* A simple URL

        display/cwid-cim9006
* A POST request with parameters

        admin/developerAjax POST Accept(text/plain) query='this and that'
* A simple request from a logged in user

        LOGIN tadmin@mydomain.edu Password ==> display/cwid-cim9006
