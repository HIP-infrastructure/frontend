# Nextcloud Migration

In order to move Nextcloud, config and data, to a new installation, here are a few tips
- copy the original nextcloud-docker/db folder to the new installation nextcloud-docker/db
- copy the nextcloud-docker/secrets folder to the new nextcloud-docker/secrets
- copy the /mnt/nextcloud-dp/nextcloud/config/config.php . At the end of the new Nextcloud install, copy this file as the new Nextcloud config. 
- Move the old /mnt/nextcloud-dp/nextcloud/data to the new installation
