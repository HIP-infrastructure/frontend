const path = require("path");
const dotenv = require("dotenv");
const { execSync } = require("child_process");

const which = cmd => execSync(`which ${cmd}`).toString().trimEnd();
const relative = (...dir) => path.resolve(__dirname, ...dir);

const env = dotenv.config({ path: relative("../.env") }).parsed || {};

// Merge .env variables with process.env, with process.env taking precedence
const whitelist = ['REMOTE_APP_API', 'COLLAB_REMOTE_APP_API']; 
whitelist.forEach(key => {
  if (process.env[key]) {
    env[key] = process.env[key];
  }
});

const caddy = which("caddy");

module.exports = {
  apps: [
   
    {
      script: caddy,
      args: 'run',
      name: 'caddy_frontend',
      cwd: relative('../caddy'),
      watch: relative('../caddy'),
      env
    },
    {
      script: 'sudo node gateway/dist/main.js',
      cwd: relative('..'),
      name: 'gateway',
      watch: relative('gateway/dist/main.js'),
      env
    },
  ],
};
