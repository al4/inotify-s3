inotify-s3
==========

A bit of bash-fu to upload files from an AWS EC2 instance to S3. The entrypoint script will monitor
the directory `/watch` inside the container, and upload them when they have finished being written
to (inotify `CLOSE_WRITE` event).

Status
------

This project is not in active use, and no longer maintained. It was in use for a few years before
being rewritten in Go. That version is not public.

I'm uploading it, because it was a fun little project that solved a problem.

The use case was uploading Java heap and thread dumps from live environments. I definitely wouldn't
trust it for anything important.

Usage
-----

```bash
docker run -v /var/spool/watch:/watch -i inotify-s3:latest s3://path-to-my-bucket.example.com/directory
```

The instance ID is appended to the path, so a file name foo.txt found in /var/spool/watch would be
pushed to the path:
`s3://path-to-my-bucket.example.com/directory/<instance-id>/foo.txt`

Region can be set by adding `-e AWS_REGION="aws-region"` to the docker args.

Notes
-----

* This container is designed to handle terminate/interrupt signals, shutdown gracefully and wait
  until any S3 uploads in progress have completed before exiting. Ensure you have appropriate
  timeouts set (e.g. `docker stop -t 120 inotify-s3`, `TimeoutStopSec=120` in systemd).
* In testing, `CLOSE_WRITE` events did not fire on MacOS, presumably because the Darwin kernel does
  not implement them.
