const path = require("path");
const dotenv = require("dotenv");
const { execSync } = require("child_process");

const which = cmd => execSync(`which ${cmd}`).toString().trimEnd();
const relative = (...dir) => path.resolve(__dirname, ...dir);

const gunicorn = which("gunicorn");

const env = dotenv.config({ path: relative("../.env") }).parsed;

const data = "/mnt/nextcloud-dp/nextcloud/data";
const collab_data = "/mnt/collab";
const port = "3444"
const auth_port = "3445"
const collab_port = "3447"
const collab_auth_port = "3448"
const host = "0.0.0.0";
const suffix = "files";
const cert = env.GHOSTFS_CERT;
const key = env.GHOSTFS_KEY;

module.exports = {
  apps: [
    {
      script: "su",
      cwd: relative('../ghostfs'),
      name: 'ghostfs',
      watch: false,
      env: {
        "LD_LIBRARY_PATH": "/home/dsr_adm/app-in-browser/libssl/out"
      },
      args: `-s /bin/sh www-data -c "./GhostFSLauncher.sh --server --root ${data} --bind ${host} --suffix ${suffix} --key ${key} --cert ${cert} --port ${port} --auth-port ${auth_port}"`,
    },
    {
      script: "su",
      cwd: relative('../ghostfs'),
      name: 'ghostfs_collab',
      watch: false,
      env: {
        "LD_LIBRARY_PATH": "/home/dsr_adm/app-in-browser/libssl/out"
      },
      args: `-s /bin/sh www-data -c "./GhostFSLauncher.sh --server --root ${collab_data} --bind ${host} --suffix ${suffix} --key ${key} --cert ${cert}  --port ${collab_port} --auth-port ${collab_auth_port}"`,
    },
    {
      script: gunicorn,
      args: '--workers 5 --timeout 120 --bind 127.0.0.1:3446 --pythonpath auth_backend auth_backend:app',
      name: 'gunicorn_auth_backend',
      cwd: relative('../ghostfs'),
      watch: relative('../ghostfs/auth_backend'),
      env: {
        "LD_LIBRARY_PATH": "/home/dsr_adm/app-in-browser/libssl/out"
      },
      interpreter: 'python3' 
    }
  ],
};
