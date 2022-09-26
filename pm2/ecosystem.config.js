const path = require("path");
const dotenv = require("dotenv");
const { execSync } = require("child_process");

const which = cmd => execSync(`which ${cmd}`).toString().trimEnd();
const relative = (...dir) => path.resolve(__dirname, ...dir);

const auth_backend_env = dotenv.config({ path: relative("../ghostfs/auth_backend/auth_backend.env") }).parsed;
const frontend_env = dotenv.config({ path: relative("../.env") }).parsed;

const caddy = which("caddy");

module.exports = {
  apps: [
   
    {
      script: caddy,
      args: 'run',
      name: 'caddy_frontend',
      cwd: relative('../caddy'),
      watch: relative('../caddy'),
      auth_backend_env
    },
    {
      script: 'gateway/dist/main.js',
      cwd: relative('..'),
      name: 'gateway',
      watch: relative('gateway/dist/main.js'),
      frontend_env
    },
  ],
};
