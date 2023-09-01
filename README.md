# Automated Backup and Restore System

The Automated Backup and Restore System is a shell script-based solution for securely backing up specified directories, encrypting the backups, and enabling easy data restoration. This README provides instructions on how to use the system effectively.

## Prerequisites

- Linux-based operating system
- Bash shell (usually pre-installed)
- GPG (GNU Privacy Guard) for encryption (install if not available)

## Usage

1. **Clone or Download the Repository:**

   Clone or download this repository to your local machine.

2. **Navigate to the Project Directory:**

   Open a terminal and navigate to the project directory.

3. Run backup.sh to backup your files.
```bash
sudo bash backup.sh
```
4. Enter the necessary parameters:
    source_dirs: Array of source directories you want to back up.
    dest_dir: Directory where the backup files will be stored.
    encryption_key: Passphrase for encrypting the backup files.
    n: Backup period in days (how old the files should be to trigger a backup).
5. Run restore.sh to restore your files.
```bash
sudo bash restore.sh
```
6. Enter the necessary parameters:
    source_dir: Path to the encrypted backup file you want to restore.
    decryption_key: Passphrase for decrypting the backup file.
    dest_dir: Directory where the restored files will be placed.
7. Run cron.sh in case you need to run the system periodically,you can adjust it the way suits your needs.


## Important Notes

-Keep your encryption keys and passphrases secure and do not share them.
-Backup and restore operations require appropriate permissions for the source and destination directories so you might need to use 'sudo' .


## Conclusion

The Automated Backup and Restore System simplifies data protection by automating backup processes and providing a straightforward method for data restoration. By following these instructions, you can easily configure, run, and schedule backups according to your requirements.
