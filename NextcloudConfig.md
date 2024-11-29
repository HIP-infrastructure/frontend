# nextcloud-docker

Add the following lines to `./caddy/Caddyfile`
``` 
root * /var/www/html
file_server
php_fastcgi /* 127.0.0.1:9000

header {
	# enable HSTS
	Strict-Transport-Security max-age=31536000;
}

redir /.well-known/carddav /remote.php/dav 301
redir /.well-known/caldav /remote.php/dav 301
```

- `make configure-nextcloud`
- Once Nextcloud is installed, we need to replace the created php-settings by our own in order to parametrize it for docker etc.
  - `sudo rm -rf /mnt/nextcloud-dp/php-settings`
  - `sudo cp -r php-settings /mnt/nextcloud-dp`

- Go to the nextcloud folder and `docker compose stop && docker compose up -d` It will fail, again. 
  - `make occ c=maintenance:install`
  - Nextcloud install asks fo a password for admin, use the one provided in secrets in [nextcloud_admin_password.txt]

- Add some params to the Nextcloud php config in  `/mnt/nextcloud-dp/nextcloud/config/config.php`
```
    'htaccess.RewriteBase' => '/',    
    'htaccess.IgnoreFrontController' => true,     
    'defaultapp' => 'hip',
    'trusted_domains' => ['hip.local'],
```
- Open your browser to your ip or hostname
- Access NextCloud with admin/[nextcloud_admin_password.txt]
- NextCloud could complain about Access through untrusted domain, and in that case, re-add your domain to the `/mnt/nextcloud-dp/nextcloud/config/config.php` file again. This yhould fix it.
- sudo pm2 restart all to restart ghostfs

#### Keycloak, Social-login app, OIDC client, groups

Social login is a Nextcloud app, customized for our need, helping the OIDC login process for users.



- With the current Keycloak setup, you need an EBRAINS account. 
  - Either on production https://iam.ebrains.eu/register or development, https://[iam-provider-url]/register
- Center will be mapped to EBRAINS keycloak groups, we will need to add you there manually on EBRAINS for authorization purposes.
- Create a group for your Center via the NC api.
  - `make occ c="group:add  --display-name CHUV chuv"`

- Open settings under you profile, on the top right.
- Choose "Social Login" under the administration menu, in the left sidebar  
  - [x] Update user profile every login
  - [x] Hide default login
  - [x] Button text without prefix


- Add a Custom OpenID Connect client.

| Key | Value |
| --- | --- |
| Internal name | dev.thehip.app |
| Title | EBRAINS-INT |
| Authorize url | https://[iam-provider-url]/auth/realms/hbp/protocol/openid-connect/auth |
| Token url | https://[iam-provider-url]/auth/realms/hbp/protocol/openid-connect/token |
| Display name claim (optional) | name |
| Username claim (optional) | preferred_username |
| User info URL (optional) | https://[iam-provider-url]/auth/realms/hbp/protocol/openid-connect/userinfo | 
| Client Id | [iam-client_id] | 
| Client Secret | [iam-client_secret] |
| Scope | openid group profile email roles team | 
| Groups claim (optional) | roles.group |

Add group mapping 

| Key | Value |
| --- | --- |
| group-HIP-dev-CHUV | chuv | 

Save everything, logout, and try to login with your credentials

if you want to migrate an existing install to a new location, here are a few tips

### Nextcloud Migration

In order to move Nextcloud, config and data, to a new installation, here are a few tips
- copy the originaldb folder to the new installation db folder
- copy the secrets folder to the new secrets folder
- copy the /mnt/nextcloud-dp/nextcloud/config/config.php . At the end of the new Nextcloud install, copy this file as the new Nextcloud config. 
- Move the old /mnt/nextcloud-dp/nextcloud/data to the new installation

