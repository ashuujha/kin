import {copyFileSync,mkdirSync} from 'node:fs';
const dist='apps/recipient-web/dist';
for(const path of ['s','e','privacy','auth/callback']) {
  mkdirSync(`${dist}/${path}`,{recursive:true});
  copyFileSync(`${dist}/index.html`,`${dist}/${path}/index.html`);
}
console.log('Prepared direct browser and OAuth callback routes for static hosting.');
