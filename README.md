<p align="center">
  <img src="logo.img" alt="pibackup logo" />
  <img src="https://img.shields.io/badge/bash-5.0.3-lightgray" alt="bash version" />
</p>

# pibackup.sh

`pibackup.sh` is a bash script that automatically dump a PI sdcard as a shrunk image to a [remote] directory, and handles rotation of several files. It is recommended to automate this script using `systemd` timers or `cron`, so the backups are done on a regular basis and without any interaction.

This is still WIP work, let me know if you have ideas about how to improve.

## Table of content

1. [Background](#background)
2. [Usage](#usage)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
   1. [Local usage](#local-usage)
   2. [Remote usage](#remote-usage)
5. [Example](#example)
6. [Automation](#automation)
   1. [systemd timer](#systemd-timer)
   2. [cron job](#cron-job)
8. [Contributing](#contributing)

## Background

Once during a house move, I unplugged a Raspberry PI and somehow it killed the SD card. All my code was saved already, but I lost hours of my time spent on configuring and pimping my PI. I was so mad at myself for not doing backups that I started to look into automatic backup tools, but I didn't find anything that pleased me enough. So I bought an external drive and started this project.
Hope it will be useful for more people than just myself!

## Usage

```bash
$ ./pibackup.sh -h
---
pibackup.sh 0.4.1
---

usage: pibackup.sh -o <output> [options]

Required parameters:
  -o, --output-dir [DIRECTORY]  Where backup will be saved and rotated.

Optional parameters:
  -d, --destination [HOSTNAME]  Name of the destination host. Default:
                                  self ($ uname -n)
  -h, --help                    Display this message.
  -n, --image-name [NAME]       Rename the backup file as '<NAME>.img.x'.
                                  Default: self ($ uname -n)
  -r, --rotation-count [COUNT]  Quantity of files to be kept. Default: 8
  -t, --tmp-dir [DIRECTORY]     Temporary directory to use on the remote node. Default: /tmp
  -q, --quiet                   Silent mode.
  -z, --gzip                    Compress image using gzip.
  -Z, --xz                      Compress image using xz.
```

## Prerequisites

1. External disk space: At the moment, you cannot dump your sd card on itself; you need a proper storage. For instance, I have a disk drive plugged to my master Raspberry PI that other nodes will remotely interact with.

2. Good local network: If doing remote backup, you need to make sure your network is efficiently configured. I had speed issues at home, so I had to make another local network, which greatly increased the backup upload speed.

3. This project uses [PiShrink](https://github.com/Drewsif/PiShrink) from Drewsif. Make sure to install it before.

```bash
$ which pishrink.sh
/usr/local/bin/pishrink.sh
```

4. It also depends on `sshfs`:

```bash
sudo apt install sshfs
```

5. If using `cron` you may need `postfix` to deliver local mails:

```bash
sudo apt install postfix
```

## Installation

This section is subject to change as I am not happy with how it currently works.

### Local usage

If you want to store the image on the same PI, you will need to install both `pibackup.sh` and `rotate.sh`

```bash
for script in pibackup.sh rotate.sh; do wget https://raw.githubusercontent.com/Chocorean/pibackup/master/$script; chmod +x $script; sudo mv $script /usr/local/bin; done
```

### Remote usage

If you want to store the image on a remote node, make sure to follow the previous step on the remote node. Then, you just need to install `pibackup.sh`:

```bash
wget https://raw.githubusercontent.com/Chocorean/pibackup/master/pibackup.sh
chmod +x pibackup.sh
sudo mv pibackup.sh /usr/local/bin
```

## Example

For a local backup, this is simplest you can use:

```bash
$ pibackup.sh -o /backups
[pibackup.sh] Dumping sdcard ...
[ ... dd output ... ]
[pibackup.sh] Setting permissions ...
[pibackup.sh] Shrinking image ...
[ ... pishrink.sh output ... ]
[pibackup.sh] Rotating previous images ...
[pibackup.sh] Done ...
```

If the backup is stored remotely, you need at least to specify the destination:

```bash
$ pibackup.sh -o /backups
[pibackup.sh] Mounting remote disk ...
[pibackup.sh] Dumping sdcard ...
[ ... dd output ... ]
[pibackup.sh] Setting permissions ...
[pibackup.sh] Shrinking image ...
[ ... pishrink.sh output ... ]
[pibackup.sh] Rotating previous images ...
[pibackup.sh] Unmounting remote disk ...
[pibackup.sh] Done ...
```

## Automation

The recommended way to use `pibackup.sh` is to create a `systemd` timer-service duo, but a `cron` job will work fine.

### systemd timer

You will first need to create the timer and the associated service. Then, enable and start the timer:

```bash
# systemctl enable pibackup.timer
# systemctl start pibackup.timer
```

Check [the docs](https://man.archlinux.org/man/systemd.time.7#CALENDAR_EVENTS) for `OnCalendar=` syntax.

<details>
  <summary>systemd timer</summary>
  <p>
    /etc/systemd/system/pibackup.timer
    
    [Unit]
    Description=Run pibackup.sh every monday at 2am
    
    [Timer]
    Unit=pibackup.service
    OnCalendar=Mon, 2:00

    [Install]
    WantedBy=timers.target
  </p>
</details>
    
<details>
  <summary>systemd service</summary>
  <p>
    /etc/systemd/system/pibackup.service
    
    [Unit]
    Description=Run pibackup

    [Service]
    Type=oneshot
    ExecStart=/usr/local/bin/pibackup.sh ...
    User=pi
  </p>
</details>

Thanks to [Mcdostone](https://github.com/Chocorean/pibackup/issues/8) for the suggestion.

### cron job

I recommend to seperate `cron` logs from `syslog` logs for easier troubleshooting. If not the case already, edit `/etc/rsyslog.conf` and uncomment `cron.*  /var/log/cron.log`.
As stated in the [Prerequisites](#prerequisites) section, you may also need to install `postfix` because `cron` sends mails if a job has an output.

**Also**, I had to set `SHELL` and `PATH` variables inside the crontab to make it work, but that might not be necessary for you.

Check [the docs](https://www.man7.org/linux/man-pages/man5/crontab.5.html) for `crontab` syntax.

<details>
  <summary>crontab example</summary>
  <p>
    $ crontab -e

    # default shell
    SHELL=/bin/bash
    # set PATH variable
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

    # Do a backup once a week on Mondays at 2am
    0 2 * * MON /usr/local/bin/pibackup.sh ...
  </p>
</details>

## Contributing

Quoting Drewsif:

> If you find a bug please create an issue for it. If you would like a new feature added, you can create an issue for it but I can't promise that I will get to it.
>
> Pull requests for new features and bug fixes are more than welcome!
