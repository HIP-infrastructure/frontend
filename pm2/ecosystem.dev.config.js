const path = require("path");
const dotenv = require("dotenv");
const { execSync } = require("child_process");

const which = cmd => execSync(`which ${cmd}`).toString().trimEnd();
const relative = (...dir) => path.resolve(__dirname, ...dir);

const env = dotenv.config({ path: relative("../.env") }).parsed;

const gunicorn = which("gunicorn");
const caddy = which("caddy");

const data = "/mnt/nextcloud-dp/nextcloud/data";
const host = "0.0.0.0";
const suffix = "files";

module.exports = {
  apps: [
    {
      script: caddy,
      args: 'run --config ../caddy/Caddyfile.dev --adapter caddyfile',
      name: 'caddy_frontend',
      cwd: relative('../caddy'),
      watch: relative('../caddy'),
      env
    }
  ],
};
