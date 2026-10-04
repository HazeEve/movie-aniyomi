import {chromium} from 'playwright';
const [f,o,w,h]=process.argv.slice(2);
const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:+w,height:+h}});
await p.goto('file://'+process.cwd()+'/'+f);await p.screenshot({path:o,omitBackground:true});await b.close();
