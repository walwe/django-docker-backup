# django-docker-backup
Backups django media and postgres db running in docker container.
 
## Usage
```
django_docker_backup.sh -m <media-volume-name> -c <db-container-name> -d <db-role> -o <output-dir>
```
- Set `-m`  to backup media directory
- Set `-c`  to backup database 
