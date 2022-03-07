# pibackup.sh

`pibackup.sh` is a bash script that automatically dump a PI sdcard as a shrunk image to a [remote] directory, and handles rotation of several files. It is recommend to run it using `cron` so the backups are done without any interaction.

At the moment, the script is not very flexible and requires manual edit to be adapted to your needs.

## Usage

```bash
$ pibackup.sh
[...]
```

## Prerequisites

This scripts uses [PiShrink](https://github.com/Drewsif/PiShrink) from Drewsif. Make sure to install it before.

```bash
$ which pishrink.sh
/usr/local/bin/pishrink.sh
```

## Installation

This section is subject to change as I am not happy with how it currently works.

### Local usage

If you want to store the image on the same PI, you will need to install both `pibackup.sh` and `rotate.sh`

```bash
$ for script in pibackup.sh rotate.sh; do wget https://raw.githubusercontent.com/Chocorean/pibackup/master/$script; chmod +x $script; sudo mv $script /usr/local/bin; done
```

### Remote usage

If you want to store the image on a remote node, make sure to follow the previous step on the remote node. Then, you just need to install `pibackup.sh`:

```bash
wget https://raw.githubusercontent.com/Chocorean/pibackup/master/pibackup.sh
chmod +x pibackup.sh
sudo mv pibackup.sh /usr/local/bin
```

## Example

```bash
$ sudo pibackup.sh
[...]
```

## Contributing

Quoting Drewsif:

*If you find a bug please create an issue for it. If you would like a new feature added, you can create an issue for it but I can't promise that I will get to it.

Pull requests for new features and bug fixes are more than welcome!*
