inotify-s3
==========

A bit of bash-fu to upload files from an AWS instance to S3. The entrypoint
script will monitor the directory `/watch` inside the container, and upload
them when they have finished being written to (inotify `close_write` event).

Usage
-----

```bash
docker run -v /var/spool/watch:/watch -i inotify-s3:latest s3://path-to-my-bucket.example.com/directory
```

The instance ID is appended to the path, so a file name foo.txt found in
/var/spool/watch would be pushed to the path:
`s3://path-to-my-bucket.example.com/directory/<instance-id>/foo.txt`

Region can be set by adding `-e AWS_REGION="aws-region"` to the docker args.

Notes
-----
* This container is designed to handle terminate/interrupt signals, shutdown
gracefully and wait until any S3 uploads in progress have completed before
exiting. Ensure you have appropriate timeouts set (e.g. `docker stop -t 120
inotify-s3`, `TimeoutStopSec=120` in systemd).
* In testing, inotify events did not fire on MacOS, presumably because the
MacOS kernel does not implement inotify, and the virtual machine doesn't
seem to generate the events either. I've read reports of inotify working
previously, hopefully it will be fixed in future.
