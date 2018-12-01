# LGTM-Generator from Dropbox

Generate LGTM image from your favorite images on [Dropbox](http://dropbox.com) !

![](https://i.gyazo.com/58fbbbee8fcc98944aa66d084054b16b.gif)

### features

+ Download an image from your Dropbox.
+ Add "LGTM" on the downloaded image.
+ Many options
  + Change "LGTM" text color.
  + Select "LGTM" text color automatically.
  + Change "LGTM" text itself.
  + Resize the image.
  + Generate Gif image.
  + Upload the image to [Gyazo](https://gyazo.com).
  + Consider the usage frequency.

## Usage

### 1. Edit settings.json

Rename `settings.json.sample` to `settings.json`.

```sh
$ mv settings.json.sample settings.json
$ vi settings.json
```

Write your access_token of Dropbox & target directory in Dropbox.  
To get access_token, you need to access [Dropbox Developers page](https://www.dropbox.com/developers) and create your app.

NOTE: The target directory is a string which starts and _ends_ with slash, e.g. `/path/to/img/`

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

### Select LGTM color automatically

Use `--auto-color` option

```sh
$ ruby lgtm-generator-from-dropbox.rb --auto-color
```

### Change LGTM string

Use `--text` option

```sh
$ ruby lgtm-generator-from-dropbox.rb --text GREAT
```

#### CJK languages support

In `settings.json`, you should add `cjk_font` as the PATH of the proper font in your local machine.

For example, 

```json
{
  "cjk_font": "/Library/Fonts/ヒラギノ丸ゴ ProN W4.ttc"
}
```

### Change LGTM image size

Use `--size` option  
`--size` should be like `640x480`

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

### Consider the use of frequency

use `--history` option

By reading `history.json` automatically, the least frequently used image will be adopted as output image.

```sh
$ ruby lgtm-generator-from-dropbox.rb --history
# history.json will be created
```
