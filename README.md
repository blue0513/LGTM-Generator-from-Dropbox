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

## Advanced Usage

### Change LGTM color

Use `--color` option

```sh
$ ruby lgtm-generator-from-dropbox.rb --color white
```

### Change LGTM image size

Use `--size` option.  
`--size` should be like `640x480`.

```sh
$ ruby lgtm-generator-from-dropbox.rb --size 640x480
```

### Generate LGTM gif

Use `--gif` option

```sh
$ ruby lgtm-generator-from-dropbox.rb --gif
# output.gif will be generated instead
```

### Upload LGTM image to Gyazo

Edit `gyazo_access_token` in settings.json.  
(You can get access_token from [here](https://gyazo.com/oauth/applications) by creating new app)

Then, use `--upload` option

```sh
$ ruby lgtm-generator-from-dropbox.rb --upload
# After uploading image, You can get the Gyazo Image URL
```
