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

## Structures
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
vivosnap prepare sub-list ./full-list 50
```
```
vivosnap capture ‘http://localhost:8080/vivo’ ./list target_directory [OVERWRITE|REPLACE]
```
```
vivosnap compare reference_directory test_directory expected_changes_file differences_directory
```
```
vivosnap re-compare differences_directory expected_changes_file new_differences_directory
```
