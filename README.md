This is a collection of various scripts I use for automatically managing snapshots on btrfs.

I use this to overcome buggy macOS TimeMachine, which periodically ask for starting a new backup after verification.

-![Your TimeMachine is not working](/Time-Machine-completed-a-verification-of-your-backups.-To-improve-reliability-Time-Machine-must-create-a-new-backup-for-you..png)

Scripts included in this repo.

- snapshot_tm.sh - take a snapshot of btrfs volume, when no one is using the volume.
- invoke_stm.sh - invoke snapshot_tm.sh till success or timeout
- scrub_data_disk.sh - check filesystem integrity
- check_and_cleanup.sh - keep recent 7 snapshots and release disk space by deleting older snapshots.




