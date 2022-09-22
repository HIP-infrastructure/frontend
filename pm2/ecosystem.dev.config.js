const path = require("path");
const dotenv = require("dotenv");
const { execSync } = require("child_process");

const which = cmd => execSync(`which ${cmd}`).toString().trimEnd();
const relative = (...dir) => path.resolve(__dirname, ...dir);

const auth_backend_env = dotenv.config({ path: relative("../ghostfs/auth_backend/auth_backend.env") }).parsed;
const frontend_env = dotenv.config({ path: relative("../.env") }).parsed;

const gunicorn = which("gunicorn");
const caddy = which("caddy");

const data = "/mnt/nextcloud-dp/nextcloud/data";
const host = "0.0.0.0";
const suffix = "files";

module.exports = {
  apps: [
    {
      script: "su",
      cwd: relative('../ghostfs'),
      name: 'ghostfs',
      watch: false,
      args: `-s /bin/sh www-data -c "./GhostFS --server --root ${data} --bind ${host} --suffix ${suffix}"`,
    },
    {
      script: gunicorn,
      args: '--workers 40 --timeout 120 --bind 127.0.0.1:3446 --pythonpath auth_backend auth_backend:app',
      name: 'gunicorn_auth_backend',
      cwd: relative('../ghostfs'),
      watch: relative('../ghostfs/auth_backend'),
      interpreter: 'python3' 
    },
    {
      script: caddy,
      args: 'run --config ../caddy/Caddyfile.dev',
      name: 'caddy_frontend',
      cwd: relative('../caddy'),
      watch: relative('../caddy'),
      auth_backend_env
    }
  ],
};
