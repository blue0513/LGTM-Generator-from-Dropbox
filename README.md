# LGTM-Generator from Dropbox

It's still WIP.

## Usage

### 1. Edit settings.json

Rename `settings.json.sample` to `settings.json`.

```sh
$ mv settings.json.sample settings.json
$ vi settings.json
```

Write your access_token of Dropbox & target directory in Dropbox.  
To get access_token, you need to access [Dropbox Developers page](https://www.dropbox.com/developers) and create your app.

### 2. Execute

You can generate LGTM image as `output.jpg`.

```sh
$ ruby lgtm-generator-from-dropbox.rb
```
